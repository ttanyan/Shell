#! /usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import json
import os
from os import path
import platform
import re
import shutil
import subprocess
import sys
import time

PYTHON_VERSION = platform.python_version()
"""
Python 2.x默认编码为ascii，考虑会使用各种中文，将默认编码设置为utf-8。Python 3.x不再支持该方法
"""
if PYTHON_VERSION.startswith("2"):
    reload(sys)
    sys.setdefaultencoding("utf-8")
"""
脚本版本信息
"""
SCRIPT_VERSION = "jimi backup.py 0.0.1"
"""
默认备份目录，是当前执行目录(不一定是脚本目录)下的bakcup目录，不存在则创建
"""
DEFAULT_ROOTDIR = 'bakcup'
"""
默认过期天数，即循环周期为10天
"""
DEFAULT_EXPIRED_DAYS = 10
"""
全备目录为full，不会改
"""
DIRPREFIX_FULL = 'full'
"""
增备目录以increment_开头，以2位数字结尾，小于10时补零
"""
DIRPREFIX_INCREMENT = 'increment_'
"""
截取时用，increment_的长度
"""
LEN_DP_INCREMENT = len(DIRPREFIX_INCREMENT)
"""
每天的秒数
"""
SECONDS_OF_DAY = 24 * 60 * 60
"""
过期目录
"""
DIR_EXPIRED = "expired"
"""
临时目录，备份结束后删除
"""
DIR_TEMP = "/tmp/jimi-dbbackup"
"""
日志目录
"""
DEFAULT_LOGDIR = '/var/log/jimi-dbbackup'


class Backupinfo(object):

    def __init__(self, rootdir, days=DEFAULT_EXPIRED_DAYS):
        self.rootdir = rootdir
        self.days = days
        self.compute()

    """
    检索备份目录，计算目录名。
    如果没有full，则使用全量备份目录；
    如果有，则使用增量备份目录
    """

    def compute(self):
        # 备份根目录
        rootdir = self.rootdir
        # 备份循环周期，天为单位
        days = self.days
        # 备份文件夹命名后缀起始点，如果为0，备份目录为full，否则为increment_01,increment_02,increment_03....
        startpoint = 0
        # 声明变量
        # 本次备份目录全路径
        backupdir = None
        # 本次备份目录名
        backupname = None
        # 本次已有目录，如果为全量备份，该列表为空
        incdirs = list()
        # 本次过期目录，如果为第一次备份，该列表为空
        expiredirs = list()
        # 全量备份目录
        fulldir = '%s/%s' % (rootdir, DIRPREFIX_FULL)
        """
        检查根目录是否存在，不存在时进行第一次全量备份(备份目录为full)，存在时检查全量目录是否存在....
        """
        if path.exists(self.rootdir):
            full_existed = path.exists(fulldir)

            """
            检查全量目录是否存在，不存在时进行第一次全量备份(备份目录为full)，存在时检查全量备份目录是否超出期限...
            """
            if full_existed:
                # 计算最早的创建时间，顺便减去过期秒数
                ear_ctime = time.time() - float(days) * SECONDS_OF_DAY

                ctime = path.getctime(fulldir)

                subdirs = os.listdir(rootdir)
                # 遍历子目录列表并取出所有增量备份目录
                for subdir in subdirs:
                    fullpath_subdir = '%s/%s' % (rootdir, subdir)

                    # 如果不是增量备份目录，或者不是文件夹，跳过
                    if not subdir.startswith(DIRPREFIX_INCREMENT) or not path.isdir(fullpath_subdir):
                        continue
                    incdirs.append(subdir)
                """
                检查全量目录是否超出期限，已过期就进入全新的备份周期(进行一次全量备份)，未过期则创建新的增量
                """
                if ear_ctime > ctime:
                    # 如果全量备份目录过期，剩余增量目录也一并加入到删除目录中
                    expiredirs.append(DIRPREFIX_FULL)
                    expiredirs.extend(incdirs)
                    # startpoint = 0
                    incdirs = []
                else:
                    # 如果全量备份目录没有过期，从剩余增量目录中计算当前备份目录
                    if incdirs:
                        # 排序增量目录，找到最后一个并创建一个新的，增量加一，增量目录名称自动补0，2位数
                        incdirs.sort()
                        last_incdir = incdirs[-1]
                        startpoint = int(last_incdir[LEN_DP_INCREMENT:]) + 1
                    else:
                        startpoint = 1
        """
        根据上文计算得到的startpoint创建本次备份目录
        """
        if startpoint:
            backupname = '%s%02d' % (DIRPREFIX_INCREMENT, startpoint)
            backupdir = '%s/%s%02d' % (rootdir, DIRPREFIX_INCREMENT, startpoint)
        else:
            backupname = DIRPREFIX_FULL
            backupdir = fulldir

        """
        已过期目录列表整理，备份时，上次备份文件会暂存入过期目录，并清除过期目录中的备份文件(上上次的)
        """
        deldirs = list()
        if startpoint == 0:
            expired_rootdir = "%s/%s" % (rootdir, DIR_EXPIRED)
            if path.exists(expired_rootdir):
                subdirs = os.listdir(expired_rootdir)
                # 遍历子目录列表并取出所有增量备份目录
                for subdir in subdirs:
                    fullpath_subdir = '%s/%s' % (expired_rootdir, subdir)
                    # 如果不是增量备份目录，或者不是文件夹，跳过
                    if (subdir.startswith(DIRPREFIX_FULL) or subdir.startswith(DIRPREFIX_INCREMENT)) and path.isdir(
                            fullpath_subdir):
                        deldirs.append(subdir)
        # 赋值
        self.backupdir = backupdir
        self.backupname = backupname
        self.deldirs = deldirs
        self.expiredirs = expiredirs
        self.incdirs = incdirs
        self.startpoint = startpoint

    def __str__(self):
        return self.__dict__.__str__()


"""
1、将expired过期目录中的历史备份文件移动到tmp目录中待删除
2、将备份目录中的过期备份文件移动到expired过期目录中
"""


def expired(backupinfo):
    expired_rootdir = "%s/%s" % (backupinfo.rootdir, DIR_EXPIRED)

    # 创建过期根目录
    if not path.exists(expired_rootdir):
        os.makedirs(expired_rootdir)

    # 有需要删除的文件，该文件原本就在过期目录中
    if backupinfo.deldirs:
        print
        u"删除文件"
        for deldir in backupinfo.deldirs:
            fullpath_deldir = "%s/%s" % (expired_rootdir, deldir)
            tmppath_deldir = "%s/%s" % (DIR_TEMP, deldir)
            print
            "\t%s(%s)" % (fullpath_deldir, tmppath_deldir)
            shutil.move(fullpath_deldir, tmppath_deldir)
    # 有过期文件，需要移除
    if backupinfo.expiredirs:
        print
        u"过期文件"
        for expiredir in backupinfo.expiredirs:
            fullpath_backupdir = "%s/%s" % (backupinfo.rootdir, expiredir)
            fullpath_expiredir = "%s/%s" % (expired_rootdir, expiredir)
            print
            "\t%s(%s)" % (fullpath_backupdir, fullpath_expiredir)
            shutil.move(fullpath_backupdir, fullpath_expiredir)


"""
如果是增量备份，删除增量备份。如果是全量备份：
1、删除现有备份目录及文件
2、将expired过期目录中的文件还原到备份目录中
3、临时文件目录还原到过期目录中
"""


def rollback(backupinfo):
    backupdir = backupinfo.backupdir
    isfull = backupdir.endswith('full')
    expired_rootdir = "%s/%s" % (backupinfo.rootdir, DIR_EXPIRED)
    if path.exists(backupdir):
        print
        u"删除备份目录 %s" % backupdir
        shutil.rmtree(backupdir)

    if backupinfo.expiredirs:
        print
        u"恢复文件到备份目录"
        for expiredir in backupinfo.expiredirs:
            fullpath_expiredir = "%s/%s" % (expired_rootdir, expiredir)
            fullpath_backupdir = "%s/%s" % (backupinfo.rootdir, expiredir)
            print
            "\t%s(%s)" % (fullpath_expiredir, fullpath_backupdir)
            shutil.move(fullpath_expiredir, fullpath_backupdir)

    # 有需要删除的文件，该文件原本就在过期目录中
    if backupinfo.deldirs:
        print
        u"恢复文件到过期目录"
        for deldir in backupinfo.deldirs:
            tmppath_deldir = "%s/%s" % (DIR_TEMP, deldir)
            fullpath_deldir = "%s/%s" % (expired_rootdir, deldir)
            print
            "\t%s(%s)" % (tmppath_deldir, fullpath_deldir)


def dobackup(defaultsfile, user, password, basedir, backupdir):
    logname = time.strftime("%Y-%m-%d_%H%M%S.log", time.localtime())
    log_fullpath = "%s/%s" % (DEFAULT_LOGDIR, logname)
    isfull = backupdir.endswith('full')
    args = ['innobackupex', '--defaults-file=%s' % defaultsfile, '--user=%s' % user, '--password=%s' % password,
            '--no-timestamp']
    if not isfull and basedir:
        args.append('--incremental-basedir=%s' % basedir)
        args.append('--incremental')
    args.append(backupdir)

    showargs = args[:]
    showargs[3] = '--password='
    print
    ''
    print
    u'执行脚本: \n\t%s ' % ' '.join(showargs)
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lastline = ""
    with open(log_fullpath, "w+") as f:
        while p.poll() is None:
            line = p.stdout.readline()
            line = line.strip()
            f.write(line + "\n")
            if line:
                lastline = line
    print
    ''
    print
    u'备份结束，日志文件: \n\t%s' % log_fullpath
    print
    ''
    print
    lastline
    return lastline.find('completed OK')


def docompress(gzname, gzdir):
    args = ['tar', '-zcPf', gzname, gzdir]
    print
    u"开始打包: \n\t%s" % ' '.join(args)
    p = subprocess.Popen(args)
    p.wait()


def cleartmp():
    print
    u"清空临时目录"
    shutil.rmtree(DIR_TEMP)


def main():
    # python backup.py --user=root --password=123 --backroot=backup --days=10 --compress --copydir=oss
    parser = argparse.ArgumentParser(
        prog='bakcup-script\n\n\tpython backup.py --user=root --password=123 --backroot=backup --days=10 --compress --copydir=/oss\n\n')
    parser.add_argument('-v', '--version', action="store_true", help=u'显示当前脚本版本信息,%s' % SCRIPT_VERSION)
    parser.add_argument('-u', '--user', help=u'MySQL用户名')
    parser.add_argument('-p', '--password', help=u'MySQL密码')
    parser.add_argument('-b', '--backroot', help=u'备份根目录，默认为当前目录下的%s' % DEFAULT_ROOTDIR, default=DEFAULT_ROOTDIR)
    parser.add_argument('-c', '--config', help=u'MySQL配置文件, 默认为/etc/my.cnf，如果mysql配置文件不在/etc下，请指定',
                        default='/etc/my.cnf')
    parser.add_argument('-d', '--days',
                        help=u'备份循环周期，以天为单位，默认为%d。设置为0时会立即执行全备，并移除备份目录下的其它文件(视作过期)' % DEFAULT_EXPIRED_DAYS,
                        default=DEFAULT_EXPIRED_DAYS)
    parser.add_argument('-gz', '--compress', action="store_true", help=u'以gzip格式打包备份目录', default=False)
    parser.add_argument('-f', '--copydir',
                        help=u'复制备份目录到指定目录。如果指定了-gz，会复制备份目录的打包文件(tar.gz)到指定目录。通过ossfs挂载阿里云存储后，可将文件复制到OSS中')
    args = parser.parse_args()

    if args.version:
        print
        'Python %s' % platform.python_version()
        print
        'backup.py version %s' % SCRIPT_VERSION
        subprocess.call(['innobackupex', '-v'])
        exit(0)
    elif not args.user:
        print
        u'error: MySQL用户名未填写(需要Database和数据库文件权限)'
        exit(0)
    elif not args.password:
        print
        u'error: MySQL密码未填写'
        exit(0)

    print
    u'开始备份- %s' % time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    # 创建日志文件目录
    if not path.exists(DEFAULT_LOGDIR):
        os.makedirs(DEFAULT_LOGDIR)
    # 创建临时目录
    if not path.exists(DIR_TEMP):
        os.makedirs(DIR_TEMP)
    # 创建备份根目录
    if not path.exists(args.backroot):
        os.makedirs(args.backroot)
    backroot = args.backroot
    backupinfo = Backupinfo(args.backroot, args.days)
    print
    backupinfo

    expired(backupinfo)
    # success = True
    basedir = ''
    if backupinfo.startpoint > 1:
        # 增备
        basedir = '%s/%s%02d' % (backupinfo.rootdir, DIRPREFIX_INCREMENT, backupinfo.startpoint - 1)
    elif backupinfo.startpoint == 1:
        basedir = '%s/%s' % (backupinfo.rootdir, DIRPREFIX_FULL)

    success = dobackup(args.config, args.user, args.password, basedir, backupinfo.backupdir)
    if success:
        print
        "SUCCESS!!!"
        if args.compress:
            gzname = '%s.tar.gz' % backupinfo.backupname
            gzfilepath = '%s/%s' % (backupinfo.rootdir, gzname)
            docompress(gzfilepath, backupinfo.backupdir)
            if args.copydir and path.exists(gzfilepath):
                todaytime = time.strftime("%Y-%m-%d_%H%M%S", time.localtime())
                tofile = '%s/%s-%s' % (args.copydir, todaytime, gzname)
                print
                u"复制文件: \n\t%s -- %s" % (gzfilepath, tofile)
                shutil.move(gzfilepath, tofile)
        cleartmp()
    else:
        print
        "FAILED!!!"
        print
        u"开始回滚"
        rollback(backupinfo)
    print
    u'结束备份- %s' % time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())


if __name__ == "__main__":
    if len(sys.argv) == 1:
        exit(0)
    main()

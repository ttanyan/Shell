appName=web
releaseName="jimi-frc-"$appName
jenkinsName="jimi_fkc_"$appName
file_path=/home/jimi/fkc/service/$appName/
jenkins_jar=/home/jimi/.jenkins/workspace/$jenkinsName/$releaseName/target/$releaseName


rm -rf /data1/logs/$appName/**
echo "删除历史日志"

cd $file_path
rm -f ${releaseName}".jar"
echo "删除文件"${releaseName}".jar"

rm -rf lib
echo "删除lib文件"

echo "开始复制文件"
cp -r $jenkins_jar/${releaseName}".jar" $file_path
cp -r $jenkins_jar/lib $file_path


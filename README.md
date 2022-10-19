# count_docker_for_adv_sec

This script will estimate the number of unique Docker images introduced in the last 3 months into you Artifactory.

Pre-requites:
1) Have the JFrog CLI installed and available on you path under <i>jf</i>. (see: https://jfrog.com/getcli/)
2) Config the JFrog CLI with you Artifactory connection details as **an admin user** (see: https://www.jfrog.com/confluence/display/CLI/JFrog+CLI#JFrogCLI-JFrogPlatformConfiguration)


Running the script:
<br>
**Note:** This script will iterate over all of you Docker repositories and might cause increased workload on Artifactory and the DB through the duration of the execution.
It is recommended not to execute it during peak hours.

In order to run the script, execute <i>countDocker.sh<i>



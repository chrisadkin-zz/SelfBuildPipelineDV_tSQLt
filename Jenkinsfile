def BranchToPort(String branchName) {
    def BranchPortMap = [
        [branch: 'master'   , port: 15565],
        [branch: 'Release'  , port: 15566],
        [branch: 'Feature'  , port: 15567],
        [branch: 'Prototype', port: 15568],
        [branch: 'HotFix'   , port: 15569]
    ]
    BranchPortMap.find { it['branch'] ==  branchName }['port']
}

def PowerShell(psCmd) {
    bat "powershell.exe -NonInteractive -ExecutionPolicy Bypass -Command \"\$ErrorActionPreference='Stop';$psCmd;EXIT \$global:LastExitCode\""
}

def StartContainer() {
    PowerShell "If (\$((docker ps -a --filter \"name=SQLLinux${env.BRANCH_NAME}\").Length) -eq 2) { docker rm -f SQLLinux${env.BRANCH_NAME} }"
    docker.image('microsoft/mssql-server-linux').run("-e ACCEPT_EULA=Y -e SA_PASSWORD=P@ssword1 --name SQLLinux${env.BRANCH_NAME} -d -i -p ${BranchToPort(env.BRANCH_NAME)}:1433")    
    PowerShell "While (\$((docker logs SQLLinux${env.BRANCH_NAME} | select-string ready | select-string client).Length) -eq 0) { Start-Sleep -s 1 }"
    bat "sqlcmd -S localhost,${BranchToPort(env.BRANCH_NAME)} -U sa -P P@ssword1 -Q \"EXEC sp_configure 'show advanced option', '1';RECONFIGURE\""
    bat "sqlcmd -S localhost,${BranchToPort(env.BRANCH_NAME)} -U sa -P P@ssword1 -Q \"EXEC sp_configure 'clr enabled', 1;RECONFIGURE\""
    bat "sqlcmd -S localhost,${BranchToPort(env.BRANCH_NAME)} -U sa -P P@ssword1 -Q \"EXEC sp_configure 'clr strict security', 0;RECONFIGURE\""
}

def DeployDacpac() {
    def SqlPackage   = "C:\\Program Files\\Microsoft SQL Server\\140\\DAC\\bin\\sqlpackage.exe"
    def SourceFile   = "SelfBuildPipelineDV_tSQLt\\bin\\Release\\SelfBuildPipelineDV_tSQLt.dacpac"
    def ConnString = "server=localhost,${BranchToPort(env.BRANCH_NAME)};database=SsdtDevOpsDemo;user id=sa;password=P@ssword1"
    unstash 'theDacpac'
    bat "\"${SqlPackage}\" /Action:Publish /SourceFile:\"${SourceFile}\" /TargetConnectionString:\"${ConnString}\" /p:ExcludeObjectType=Logins"
}

node('master') {
    stage('git checkout') {     
        timeout(time: 5, unit: 'SECONDS') {
            checkout scm
        }
    }
    stage('build dacpac') {
        bat "\"${tool name: 'Default', type: 'msbuild'}\" /p:Configuration=Release"
        stash includes: 'SelfBuildPipelineDV_tSQLt\\bin\\Release\\SelfBuildPipelineDV_tSQLt.dacpac', name: 'theDacpac'
    }

    stage('start container') {
        timeout(time: 20, unit: 'SECONDS') {
            StartContainer()
        }
    }

    stage('deploy dacpac') {
        try {
            timeout(time: 60, unit: 'SECONDS') {
                DeployDacpac()
            }
        }
        catch (error) {
            throw error
        }
    }
    
    stage('run tests') {
        bat "sqlcmd -S localhost,${BranchToPort(env.BRANCH_NAME)} -U sa -P P@ssword1 -d SsdtDevOpsDemo -Q \"EXEC tSQLt.RunAll\""
        bat "sqlcmd -S localhost,${BranchToPort(env.BRANCH_NAME)} -U sa -P P@ssword1 -d SsdtDevOpsDemo -y0 -Q \"SET NOCOUNT ON;EXEC tSQLt.XmlResultFormatter\" -o \"${WORKSPACE}\\SelfBuildPipelineDV_tSQLt.xml\"" 
        junit 'SelfBuildPipelineDV_tSQLt.xml'
    }
}

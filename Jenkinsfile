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
    docker.image('microsoft/mssql-server-linux:2017-latest').run("-e ACCEPT_EULA=Y -e SA_PASSWORD=P@ssword1 --name SQLLinux${env.BRANCH_NAME} -d -i -p  ${BranchToPort(env.BRANCH_NAME)}:1433")    
    bat "sqlcmd -S localhost,${BranchToPort(env.BRANCH_NAME)} -U sa -P P@ssword1 -Q \"EXEC sp_configure 'clr enabled', 1;EXEC sp_configure 'clr strict security', 0;RECONFIGURE\""
    bat "sqlcmd -S localhost,${BranchToPort(env.BRANCH_NAME)} -U sa -P P@ssword1 -Q \"EXEC sp_configure 'show advanced option', '1';RECONFIGURE\""
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
        checkout scm
        print env.JOB_NAME
        print env.WORKSPACE
        print env.GIT_URL
    }
    stage('build dacpac') {
        bat "\"${tool name: 'Default', type: 'msbuild'}\" /p:Configuration=Release"
        stash includes: 'SelfBuildPipelineDV_tSQLt\\bin\\Release\\SelfBuildPipelineDV_tSQLt.dacpac', name: 'theDacpac'
    }

    stage('start container') {
        StartContainer()
    }

    stage('deploy dacpac') {
        try {
            DeployDacpac()
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

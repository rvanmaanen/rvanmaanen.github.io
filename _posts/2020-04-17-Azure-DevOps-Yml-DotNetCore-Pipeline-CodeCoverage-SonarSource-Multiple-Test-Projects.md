---
layout: post
title:  "Creating an Azure DevOps pipeline for .NET Core with multiple test projects, SonarQube, ReportGenerator & more"
categories: Azure DevOps .NET Core Code Coverage SonarQube
description: A guide on enabling code coverage and more in Azure Devops and SonarQube with multiple .NET Core test projects 
excerpt_separator: <!--excerpt_end-->
image: /assets/code_coverage/magnifier.png
permalink: sonarqube-code-coverage-dotnetcore-multiple-test-projects
---

```yml
trigger:
  branches:
    include:
    - master

pool:
  name: Default
  demands:
  - Agent.OS -equals Linux
  
variables:
  buildConfiguration: Release
  project: '$(Build.SourcesDirectory)/Project/Project.sln'
  testOutputDirectory: '$(Agent.TempDirectory)/testresults'
  disable.coverage.autogenerate: true

steps:
- task: SonarCloudPrepare@1
  inputs:
    SonarCloud: 'SonarCloud'
    organization: 'organization'
    scannerMode: 'MSBuild'
    projectKey: 'projectKey'
    projectName: 'projectName'
    extraProperties: |
        sonar.cs.vstest.reportsPaths=$(TestOutputDirectory)/*.trx
        sonar.coverageReportPaths=$(TestOutputDirectory)/mergedcoveragereport/SonarQube.xml
		sonar.coverage.exclusions=**/Migrations/*.cs,**/*Tests*/**/*

- task: UseDotNet@2
  displayName: 'Install .NET Core 2.x runtime as it is needed for SonarCloud plugin'
  inputs:
    packageType: 'runtime'
    version: '2.0.x'
    
- task: UseDotNet@2
  displayName: 'Use .NET Core sdk'
  inputs:
    packageType: sdk
    version: 3.1.101
    installationPath: $(Agent.ToolsDirectory)/dotnet

- task: DotNetCoreCLI@2
  displayName: 'dotnet restore private feed'
  inputs:
    command: restore
    projects: '$(project)'
    vstsFeed: '00000000-0000-0000-0000-000000000000'
    verbosityRestore: Normal

- task: DotNetCoreCLI@2
  displayName: 'dotnet build'
  inputs:
    projects: '$(project)'
    arguments: '--no-restore --configuration $(BuildConfiguration)'

- task: DotNetCoreCLI@2
  displayName: 'dotnet test'
  inputs:
    command: test
    publishTestResults: false
    projects: '$(project)'
    arguments: '--no-restore --no-build --configuration $(BuildConfiguration) --logger trx --collect:"XPlat Code Coverage" --results-directory $(TestOutputDirectory) --settings $(Build.SourcesDirectory)/coverlet.runsettings'
    
- task: reportgenerator@4
  inputs:
    reports: '$(TestOutputDirectory)/*/coverage.opencover.xml'
    targetdir: '$(TestOutputDirectory)/mergedcoveragereport'
    reporttypes: 'HtmlInline_AzurePipelines;Cobertura;SonarQube'
    assemblyfilters: '-*Tests*'
    filefilters: '-*/Migrations/*.cs'

- task: PublishCodeCoverageResults@1
  inputs:
    codeCoverageTool: 'Cobertura'
    summaryFileLocation: '$(TestOutputDirectory)/mergedcoveragereport/Cobertura.xml'
    reportDirectory: '$(TestOutputDirectory)/mergedcoveragereport'

- task: SonarCloudAnalyze@1

- task: SonarCloudPublish@1
  inputs:
    pollingTimeoutSec: '300'

- task: CopyFiles@2
  inputs:
    SourceFolder: '$(TestOutputDirectory)'
    Contents: '**'
    TargetFolder: '$(Build.ArtifactStagingDirectory)'
  condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))

- task: PublishBuildArtifacts@1
  displayName: 'Publish Artifact'
  inputs:
    ArtifactName: 'allocation-artifacts'
  condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
```



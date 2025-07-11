---
layout: post
title:  "Fixing SonarCloud code coverage condition count with multiple .NET Core test projects"
categories: Azure DevOps .NET Core Merge Code Coverage SonarCloud ReportGenerator
description: Followup on my previous guide on enabling code coverage in Azure Devops and SonarQube with multiple .NET Core test projects - Simplified solution in yml that fixes SonarCloud showing too many conditions
excerpt_separator: <!--excerpt_end-->
image: /assets/code_coverage/magnifier.png
permalink: sonarsource-showing-too-many-conditions-in-code-coverage-with-multiple-dotnetcore-test-projects
---

SonarSource made a great improvement, it will now show [conditional coverage of your tests](https://community.sonarsource.com/t/c-vb-net-sonarqube-and-sonarcloud-support-branch-condition-coverage-data/22384). Unfortunately, when using the pipeline as described in my previous blogpost, SonarCloud reports way too many conditions. For instance, a simple `if(condition)` would result in 10 possible conditions which clearly is incorrect but easy to fix.<!--excerpt_end--> We submitted a [bug report](https://community.sonarsource.com/t/sonarsource-reports-invalid-code-coverage-when-using-opencover/23357) for this.

The problem appears to be that for every test project an OpenCover file is created which shows the coverage for that single test projects. Every OpenCover file contains all statements and their conditions. SonarCloud properly merges line coverage, but it appears to sum the amount of conditions. So where the most simple if statement should have 2 conditions, SonarCloud actually reported 2x5=10 conditions (we have 5 test projects) with only 2 conditions being covered.

This resulted in a massive drop in reported code coverage, as SonarCloud immediately started using conditional coverage as part of the calculations for "code coverage". This didn't make us look great anymore and more importantly our pull requests were failing. In the screenshot below the drop in coverage is clearly visible, along with the sudden appearance of conditional coverage. Time to fix this! Just want the Yml? Scroll a bit down :)

![SonarCloud reporting incorrect condition count]({{ "/assets/code_coverage_followup/conditionswrong.png" | absolute_url }})

# What does this pipeline do?
Many of the same things that are already described [in my previous blogpost](/sonarqube-code-coverage-dotnetcore-multiple-test-projects). A summary:

1. Pool/agent selection
1. Variables are defined. The test output directory is important for the guide as it will contain all test & coverage files we need.
1. Prepares for SonarCloud analysis. We're setting it up to collect TRX files which contain testresults and also to collect a single XML file containing all code coverage. Last, we are ignoring coverage on some files.
1. Installs .NET Core 2.x runtime, as the SonarCloud plugin depends on it.
1. Installs .NET Core 3.1.101 SDK to build our software.
1. Restores NuGet packages from a private feed.
1. Builds the code with the provided configuration, while skipping the restore step for each project saving a few seconds.
1. Runs all tests, skipping restore and build steps for each project saving some more seconds. TRX files (`--logger trx`) and Cobertura files (`--collect:"XPlat Code Coverage"`) are written to the test output directory. The fact that it writes Cobertura files isn't explicit, it's just the default output of [Coverlet](https://github.com/tonerdo/coverlet).
1. Runs ReportGenerator which collects all Cobertura files (one for each test project) and merges them. The output is written to 3 different formats: An HTML report to show in the build output, a Cobertura file to publish to Azure DevOps and a SonarQube specific format used by SonarCloud. Make sure to ignore the same files as specified at step 4.
1. SonarCloud analyzes the codebase.
1. SonarCloud publishes the result to Azure DevOps to show if the Quality Gate passed for your build.
1. WhiteSource bolt runs to scan your dependencies for vulnerabilities.
1. The web project is published and zipped to the artifact staging directory.
1. The artifact staging directory contents are published as build artifacts.

# Improvements on pipeline from previous blogpost
* ReportGenerator used to create a single truth that is used by both SonarCloud and Azure DevOps. I would love to see both SonarCloud and Azure DevOps being able to deal with multiple test/coverage files, but currently this appears to be the best solution.
* No more Coverlet.runsettings file needed to set Coverlet output to OpenCover.
* No longer generating HTML dashboards with ReportGenerator (standard PublishCodeCoverageResults works fine now). So no more need of `HtmlInline_AzurePipelines` parameter or  `disable.coverage.autogenerate` variable.
* New pipeline uses SonarCloud instead of SonarQube. Be aware, this requires a different extension in Azure DevOps:

![Extensions for both SonarQube and SonarCloud]({{ "/assets/code_coverage_followup/sonarplugins.png" | absolute_url }})

# Pipeline
```yml
pool:
  name: Default
  demands:
  - Agent.OS -equals Linux
  
variables:
  buildConfiguration: Release
  project: '$(Build.SourcesDirectory)/Solution.sln'
  testOutputDirectory: '$(Agent.TempDirectory)/testresults'

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
    version: '2.x'
    
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
    arguments: '--no-restore --no-build --configuration $(BuildConfiguration) --logger trx --collect:"XPlat Code Coverage" --results-directory $(TestOutputDirectory)'
    
- task: reportgenerator@4
  inputs:
    reports: '$(TestOutputDirectory)/*/coverage.cobertura.xml'
    targetdir: '$(TestOutputDirectory)/mergedcoveragereport'
    reporttypes: 'Cobertura;SonarQube'
    assemblyfilters: '-*Tests*'
    filefilters: '-*/Migrations/*.cs'

- task: PublishCodeCoverageResults@1
  inputs:
    codeCoverageTool: 'Cobertura'
    summaryFileLocation: '$(TestOutputDirectory)/mergedcoveragereport/Cobertura.xml'

- task: SonarCloudAnalyze@1

- task: SonarCloudPublish@1
  inputs:
    pollingTimeoutSec: '300'

- task: WhiteSource Bolt@20
  inputs:
    cwd: '$(Build.SourcesDirectory)'

- task: DotNetCoreCLI@2
  inputs:
    command: publish
    publishWebProjects: True
    arguments: '--configuration $(BuildConfiguration) --output $(Build.ArtifactStagingDirectory)'
    zipAfterPublish: True
  condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))

- task: PublishBuildArtifacts@1
  inputs:
    pathtoPublish: '$(Build.ArtifactStagingDirectory)' 
    artifactName: 'artifactName'
  condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
```

# The result
For this project we're back at a proper coverage:

![SonarCloud reporting correct condition count]({{ "/assets/code_coverage_followup/conditionsfixed.png" | absolute_url }})
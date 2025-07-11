---
layout: "post"
title: "How to make two VM extensions depend on each other in ARM"
tags: ["ARM Templates", "Azure Resource Manager", "VM Extensions", "Dependencies", "Chocolatey Server", "DSC", "Desired State Configuration", "PowerShell", "Azure", "Infrastructure as Code", "Cloud Infrastructure", "Virtual Machines", "Azure VMs", "Custom Script Extension", "Configuration Management", "DevOps", "Cloud Computing", "Azure Automation", "Template Development", "Azure CLI"]
description: "How I fixed my Chocolatey Server ARM template by using DSC and a custom script extension that depend on each other"
excerpt_separator: "<!--excerpt_end-->"
permalink: "depend-on-multiple-arm-script-extensions"
---

Recently I helped [Rob Bos](https://rajbos.github.io/) by creating an ARM template, that allowed him to spin up a VM in Azure and which would host a Chocolatey Server. Rob wrote [a nice blog post](https://rajbos.github.io/blog/2018/07/20/chocolatey-server-azure) about this. As he mentions in his post, there are still some issues with the ARM template. On major thing is fixed though: The DSC step no longer fails and it's no longer necessary to manually execute PowerShell. Here's how I fixed it.<!--excerpt_end-->

{:refdef: style="text-align: center;"}
![Microsoft Azure]({{ "/assets/multiple_vm_extensions/msazure.png" | absolute_url }})
{: refdef}

# How to make PowershellDscExtension and CustomScriptExtension depend on each other in ARM
1. Add the VM and both extensions to your ARM template and give them proper names.
2. Create the dependsOn element at the CustomScriptExtension and follow the next steps to determine what to fill in here.
3. Take the type and name of the VM your extensions will run on, in the example below that would be: "Microsoft.Compute/virtualMachines/ChocolateyServer"
4. Add /extensions and then /name-of-the-extension-you-depend-on, so that would be: "Microsoft.Compute/virtualMachines/ChocolateyServer/extensions/NeverGonna"
5. Enjoy your dependency! If you need any more help, have a look at the example below or reach out!

So the key thing is: you're not depending on something by just it's name, you're depending on the (end of the) resource identifier. An easy way to find this identifier is by going to the [Azure resource explorer](https://resources.azure.com), which gives you a nice view of all the resources in your subscriptions. Just add the DSC first, then check out the identifier and then add the script.

Something to watch out for is that my extensions were actually named: "ChocServ/PowershellDscExtension" and "ChocServ/CustomScriptExtension". However, only the latter part was used in my resource identifiers. So in my dependsOn I needed to leave out the "ChocServ/" part. Again, have a look at the [Azure resource explorer](https://resources.azure.com) to find out the exact identifier.

# It should look something like this 
```    
    {
      "type": "Microsoft.Compute/virtualMachines",
      "name": ChocolateyServer",
    },
    {
      "type": "Microsoft.Compute/virtualMachines/extensions",
      "name": "NeverGonna",
      "dependsOn": [
        "Microsoft.Compute/virtualMachines/ChocolateyServer"
      ]
    },
    {
      "type": "Microsoft.Compute/virtualMachines/extensions",
      "name": "GiveYouUp",
      "dependsOn": [
        "Microsoft.Compute/virtualMachines/ChocolateyServer/extensions/NeverGonna"
      ]
    }
```

# Nice! So now I can have multiple scripts depending on each other?
Nope. One thing I learned while fixing my ARM template, is that you can't have multiple PowershellDscExtension or multiple CustomScriptExtension in one ARM template. Not sure why. You can have a single one of both though. So if you came here looking how to execute multiple PowerShell scripts, you're looking in the wrong place. There are ways to do that though and [here's a starting point](https://stackoverflow.com/questions/36372049/how-to-run-multiple-powershell-scripts-at-the-same-time). 

# Remaining issues in the Chocolatey Server ARM template
There are some small remaining issues with the ARM template, [which you can see here](https://github.com/rvanmaanen/arm.chocolateyserver/issues). Feel free to submit a pull request or add new issues if you have any. I'll try and fix them. You can also find the ChocolateyServer ARM template there.
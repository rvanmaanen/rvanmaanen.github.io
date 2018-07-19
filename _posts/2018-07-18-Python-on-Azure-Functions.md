---
layout: post
title:  "Python Azure Function with Visual Studio Code"
categories: Azure Functions Python Windows 10
description: My experience setting up an Azure Function with Python and Visual Studio Code on a Windows 10 machine
excerpt_separator: <!--excerpt_end-->
image: /assets/python_on_azure_functions/pythonfunctions_li.png
---

Googling led me to a couple of blog posts about Python on Azure Functions. Those led me to believe Python on Azure Functions is using Windows as OS, uses a very old Python version and is very slow.
Even Microsoft's own [Azure Functions Supported Languages](https://docs.microsoft.com/en-us/azure/azure-functions/supported-languages) is stating Python isn't supported on runtime 2.x.

Finally, I went to the [Azure Functions Python Worker GitHub page](https://github.com/Azure/azure-functions-python-worker) and read something a little more inspiring: Python 3.6, Linux and the 2.x runtime :-) I decided to give it a try on my Windows 10 machine with Visual Studio Code. Here is what I did and what my experience and result was like.
<!--excerpt_end-->

![Azure Functions with Python]({{ "/assets/python_on_azure_functions/pythonfunctions.png" | absolute_url }})

# Heads up
Azure Functions in Python support in Visual Studio Code is still very basic. Building, testing, debugging and publishing is still done with the CLI. Support for a truely serverless deployment via the Consumption Plan isn't there as well yet, for now you're stuck with an App Service Plan. Last, not all bindings that are available for C# are available for Python yet, so no cool Service Bus integration at this moment. [All these issues are being worked on though!](https://github.com/Azure/azure-functions-python-worker/blob/dev/README.md)

# TL;DR
What you would find if you would read this to the end, is that I ended up with a terrible exception when running from Azure. Everything works on my machine, but this definately isn't production ready yet. Hence the preview status I guess ;)

# Setting up your IDE
[Download and install Visual Studio Code](https://code.visualstudio.com/download). Make sure to install these extensions. You can find them [on the marketplace](https://marketplace.visualstudio.com/VSCode):
- Python 
- Azure Functions

You probably want some of these too if you plan to do more with VSCode:
- Visual Studio Team Services
- GitLens
- Azure CLI Tools
- REST Client
- PowerShell 
- Docker

# Setting up your development environment
Read [this tutorial](https://github.com/Azure/azure-functions-python-worker/wiki/Create-Function-(CLI)). It has some issues and differs from what we're trying to do, so just read through the tutorial, read up on anything you're not familiar with and then follow the steps listed below. 

1. Install the Azure Functions Core tools v2 [by following this guide](https://github.com/Azure/azure-functions-core-tools#installing)
1. The requirements in the tutorial state Python 3.6.4 or above. So, I installed the latest Python 3.7. Bad idea, as the scripts only work with 3.6. So I installed 3.6 next to 3.7 and unchecked the "Add to Path" option to make sure there are no conflicts. If you don't want to do anything else with Python, just install 3.6 only. You can find all installers at [the Python website](https://www.python.org/downloads/windows/)
1. Create a 3.6 virtual environment inside your soon to-be project directory, by issuing this command to the Python launcher py: `py -3.6 -m venv C:\Projects\MyFunctionApp\env`. 
- FYI: You can use `py -0` to check which Python versions are available, if you have multiple installed.
1. Next you have to activate the virtual environment. Do this by executing `C:\Projects\MyFunctionApp\env\Scripts\activate.bat`. This results in a new prompt.
- FYI: To exit the activated virtual environment, just type in the command `deactivate`
1. From within the virtual environment, issue the command `func init C:\Projects\MyFunctionApp --worker-runtime python` to initialize an empty Azure Functions App in the already existing "C:\Projects\MyFunctionApp" directory.
1. By initializing the virtual environment inside of the project directory, VSCode will automatically detect this virtual environment. Be sure to add the "env" directory to your .gitignore file! This appears to be [a best practice](https://packaging.python.org/guides/installing-using-pip-and-virtualenv/).
1. You should now have the following structure:
- C:\Projects\MyFunctionApp, containing your Azure Function App.
- C:\Projects\MyFunctionApp\env, containing a Python 3.6 virtual environment, which is just a clean Python environment, exclusively for this project.
1. Start Visual Studio code and open the folder "C:\Projects\MyFunctionApp" and click 'Yes' when asked if you want to initialize the project for optimal use with VS Code. Pick 'Python' in the next step.
![Initialize]({{ "/assets/python_on_azure_functions/initialize.jpg" | absolute_url }})<br /><br />
![Language]({{ "/assets/python_on_azure_functions/language.jpg" | absolute_url }})

Congratulations, you now have a working, empty, Python Azure Function App! :-)

# Adding a function to your app:
1. Make sure your virtual environment is being used:
- By clicking on the "Python 3.6.6 (venv)" button, bottom-left in the blue status bar, and choosing the one that points to your virtual environment if it isn't already.
![Environment]({{ "/assets/python_on_azure_functions/environment.jpg" | absolute_url }})
- You can also use the `Control-Shift-P` shortcut and type: `Python: Select Interpreter`, which results in the same dropdown.
![Interpreter]({{ "/assets/python_on_azure_functions/interpreter.jpg" | absolute_url }})
1. Open a Python terminal in VSCode by pressing `Control-Shift-P` and then type: `Python: Create Terminal`. This should supply you with a shell within your project directory and automatically activate your Python virtual environment.
![Terminal]({{ "/assets/python_on_azure_functions/terminal.jpg" | absolute_url }})
1. You can doublecheck if you're in your virtual environment by looking at the prompt, it should start with (env), or whatever your virtual environment is called. 
- FIY: If you have multiple Python versions installed, when you issue the command `python --version` from your virtual environment, it will still say 3.7.0 or whatever is on your system path. The virtual environment does have its own python executable in "Scripts\python.exe", so if you issue the command `env\Scripts\python --version` it will say 3.6.6. Not sure if or when this will be an issue. Tools such as pip (see the section about fixing missing modules) are smart enough to notice they're being run inside a virtual environment and automatically adjust.
1. Adding a function is straightforward, type: `func new`. You can then choose which kind of trigger. These are supported at this moment:
- Blob
- Cosmos DB
- HTTP
- Queue
- Timer<br />![Func new]({{ "/assets/python_on_azure_functions/funcnew.jpg" | absolute_url }})<br /><br />
![Func new 2]({{ "/assets/python_on_azure_functions/funcnew2.jpg" | absolute_url }})
1. When opening the "\_\_init\_\_.py" file from your new function, VSCode will probably complain about no linter being installed. Install it when asked for.
1. When you re-open the " \_\_init\_\_.py" file, you should get the error "Unable to import 'azure.functions'". This is correct, as that module isn't available yet. 

# Fixing your missing modules - update:
1. You probably want to adjust the requirements.txt and get rid of the whole "-e git+https://github...." line and replace it with "azure-functions". That just downloads the latest azure-functions module, without any GIT clone, manual compiling or necessity for Visual C++ 14.0. It's a whole lot faster too. No idea why this isn't the default configuration when creating a new Function App with the Azure Function Core Tools.
1. Run `pip install -r .\requirements.txt` from the Python terminal and you're good to go.

# Fixing your missing modules - the original:
1. All dependencies are listed in the requirements.txt file. You can install them by issuing this command in your Python terminal: `pip install -r .\requirements.txt`.
- If you're serious about your Python development you should have a look at [pipenv](https://docs.pipenv.org/), which addresses some issues with pip and virtual environments.
1. Installing the dependencies will probably fail with the message: "Microsoft Visual C++ 14.0 is required" and sent you to an URL which doesn't exist. Nice ;) Install [Visual Studio Build Tools 2017](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2017) to fix this. Have a look at [Windows Compilers](https://wiki.python.org/moin/WindowsCompilers) for more information. 
1. I probably did something wrong the first time installing, as I still got the same error after installing. Started up "Visual Studio Installer" again to modify my "Visual Studio Build Tools 2017" installation and noticed the workload "Visual C++ build tools" wasn't checked at all. So be sure to mark that checkbox!
- Do not uncheck any of the individual components installed by that workload, like the Windows 10 SDK. That results the following error message when installing the dependencies: "fatal error C1083: Cannot open include file: 'io.h': No such file or directory".
![Visual C++ Build Tools]({{ "/assets/python_on_azure_functions/vcbuildtools.jpg" | absolute_url }})
1. Rerun `pip install -r .\requirements.txt` and have quite some patience as it is cloning the Azure Functions Python Worker repository and builds it, I think ;)
- A "src" directory stays behind after installation, as far as I know you can safely delete this.
- FIW: You can run `pip list` to see which modules are installed.

# Running locally
1. Easy, just type `func host start` in your Python terminal. It accepts all sorts of parameters, check out [the tutorial mentioned earlier](https://github.com/Azure/azure-functions-python-worker/wiki/Create-Function-(CLI)) for those.
1. For easy testing of HTTP triggers I recommend the [REST Client extension for VSCode](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) 

![Local]({{ "/assets/python_on_azure_functions/localrun.jpg" | absolute_url }})

Now probably everything up until here was sort of smooth, so brace yourself for the next part ;)

# Publishing to Azure
1. Type in `pip freeze > requirements.txt` in your Python terminal. This generates a new requirements.txt with any new dependencies. This is used in the Docker build when publishing. 
1. Use [this magic URL](https://portal.azure.com/?websitesextension_pythonFunctions=true#create/Microsoft.FunctionApp) to enable Python when creating a new App Function. Have a look at the querystring! Btw, you must pick Linux to be able to choose Python.
- When I navigated to my new Function App the result was a HTTP 502 error for quite some time. After a while the regular "Your Function App 2.0 preview is up and running" website came up. Something was very slow.
1. Now just follow the steps from the tutorial: 
- Log into your Azure account: `func azure login`
- Set your subscription if you have more than one: `func azure subscriptions list` & `func azure account set <subscription id>`
- Publish to the function app created in step 2: `func azure functionapp publish <app name>`
1. Publishing will again take quite some time. This is a known issue and apparently is being worked on. If you're still building the azure-functions-python-worker code, it doesn't seem to end at all and gets stuck on uploading artifact.

# Trying it out!
1. After fetching the URL for my HTTP trigger from the Azure Portal, I opened my favorite browser and hit the endpoint. HTTP ERROR 500.
1. Opened up AppInsights, which gave me a totally worthless stacktrace (see below), after which I gave up. I might submit a ticket later and post a new blog with the solution if I manage to fix this.

# What next if you do manage to get something working
Well, the next thing on your list should probably be building a proper CI/CD pipeline for this. And bonus, you'll probably spend less time waiting too. You're on your own for that, but you can always reach out to me if you need any help!

# The exception (nothing below this, don't bother scrolling ;))
{% highlight text %}
Microsoft.Azure.WebJobs.Host.FunctionInvocationException:
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__15.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 275)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<TryExecuteAsync>d__12.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 75)
Inner exception System.AggregateException handled at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw:
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.WorkerLanguageInvoker+<InvokeCore>d__6.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/Rpc/WorkerLanguageInvoker.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 73)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.FunctionInvokerBase+<Invoke>d__24.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/FunctionInvokerBase.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 84)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.FunctionGenerator+<Coerce>d__3`1.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/FunctionGenerator.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 225)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionInvoker`2+<InvokeAsync>d__9.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionInvoker.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 63)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<InvokeAsync>d__23.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 532)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithWatchersAsync>d__22.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 483)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__21.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 426)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__15.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 231)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.WorkerLanguageInvoker+<InvokeCore>d__6.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/Rpc/WorkerLanguageInvoker.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 73)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.FunctionInvokerBase+<Invoke>d__24.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/FunctionInvokerBase.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 84)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.FunctionGenerator+<Coerce>d__3`1.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/FunctionGenerator.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 225)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionInvoker`2+<InvokeAsync>d__9.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionInvoker.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 63)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<InvokeAsync>d__23.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 532)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithWatchersAsync>d__22.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 483)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__21.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 426)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__15.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 231)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.WorkerLanguageInvoker+<InvokeCore>d__6.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/Rpc/WorkerLanguageInvoker.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 73)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.FunctionInvokerBase+<Invoke>d__24.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/FunctionInvokerBase.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 84)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.FunctionGenerator+<Coerce>d__3`1.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/FunctionGenerator.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 225)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionInvoker`2+<InvokeAsync>d__9.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionInvoker.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 63)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<InvokeAsync>d__23.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 532)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithWatchersAsync>d__22.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 483)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__21.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 426)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__15.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 231)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.WorkerLanguageInvoker+<InvokeCore>d__6.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/Rpc/WorkerLanguageInvoker.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 73)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.FunctionInvokerBase+<Invoke>d__24.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/FunctionInvokerBase.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 84)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Script.Description.FunctionGenerator+<Coerce>d__3`1.MoveNext (Microsoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: /azure-functions-host-2.0.11857-alpha/src/WebJobs.Script/Description/FunctionGenerator.csMicrosoft.Azure.WebJobs.Script, Version=2.0.0.0, Culture=neutral, PublicKeyToken=null: 225)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionInvoker`2+<InvokeAsync>d__9.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionInvoker.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 63)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<InvokeAsync>d__23.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 532)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithWatchersAsync>d__22.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 483)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__21.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 426)
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification (System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e)
   at Microsoft.Azure.WebJobs.Host.Executors.FunctionExecutor+<ExecuteWithLoggingAsync>d__15.MoveNext (Microsoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=nullMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: C:\projects\azure-webjobs-sdk-rqm4t\src\Microsoft.Azure.WebJobs.Host\Executors\FunctionExecutor.csMicrosoft.Azure.WebJobs.Host, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null: 231)
Inner exception System.Exception handled at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw:
Inner exception System.Exception handled at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw:
Inner exception System.Exception handled at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw:
{% endhighlight %}
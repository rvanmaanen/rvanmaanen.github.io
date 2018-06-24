---
layout: post
title:  "Blogging with Jekyll on Windows"
categories: jekyll windows
description: A quick start for anyone who wants to start blogging with Jekyll on Windows by using Ubuntu through the Windows Subsytem for Linux and GitHub pages.
---
![Logos](https://raw.githubusercontent.com/rvanmaanen/rvanmaanen.github.io/master/_images/logos.png)

So! Time to write my first blog. Something simple first, guess I need a few posts to get into this. Judging by the amount of blogs, I’m probably not the first one starting out and probably won’t be the last so I thought I’d share what I did to set up this blog.

First up, I did what I always do when I’m unsure how to solve a problem: Google it! Loads of articles, many about WordPress. But I want something different and even more important, I wanted something I trusted and for things to be simple.

What I ended up choosing, was a [Jekyll](https://jekyllrb.com/) blog on [GitHub](https://github.com/): well known to us developers, pretty easy to set up as you’ll see below, no costs, near any GIT repositories I might refer to and last bit not least, a bit of nerding involved.
For those who don't know, Jekyll is a static site generator and the integration with GitHub is great.

Mostly I followed instructions and a few guides on the internet, which I’ll refer to in the end, but here’s the summary. Btw, I assume you have knowledge of GIT and how to use it, if you don’t have a look at one of these pages:
* [Instruqt](https://play.instruqt.com/topics/git)
* [Codeschool](http://gitreal.codeschool.com/)
* [Github](https://try.github.io/levels/1/challenges/1)

<br />
# Step by step instructions:
1. We’ll start by [creating a GitHub account](https://github.com/join). Remember the username, you’ll need it in the next step.

1. [Create a Git repository](https://github.com/new) named “yourusername.github.io”. Afterwards, if you head to `https://github.com/username/username.github.io/settings` and scroll down to “GitHub pages” it should look like this: ![GitHub pages](https://raw.githubusercontent.com/rvanmaanen/rvanmaanen.github.io/master/_images/githubpages.png). <br/>You can actually stop here and just use GitHub Pages by pushing HTML files to your GIT repository. As I wanted something more fancy, I continued.

1. Next we’ll setup Jekyll locally. Here I just dove in headfirst, and started fixing the requirements listed by Jekyll. As I was about to Google how to install GCC and Make I realized I was probably doing something wrong and things should be easier. And guess what, on my Windows 10 with the Anniversary Update, things can be a lot easier by using a new feature called WSL, or Windows Subsystem for Linux. Enabling this is pretty straightforward:
	1.	Open your start menu.
	1.	Type in OptionalFeatures.exe and press enter.
	1.	Mark the checkbox next to “Windows Subsystem for Linux” and press ok.
	1.	Finish the installation and reboot when asked.<br /><br />   

1.	One more thing before actually starting with Jekyll is installing [Ubuntu from the Windows Store](https://www.microsoft.com/store/productId/9NBLGGH4MSV6). Afterwards, you have Bash on Windows! Pretty awesome :)
![Ubuntu](https://raw.githubusercontent.com/rvanmaanen/rvanmaanen.github.io/master/_images/ubuntuonwindows.png)

1.	As I just followed the guide from Jekyll at this point (which just states that you must have Bash on Ubuntu on Windows enabled and doesn’t explain how – hence steps 3 and 4), [here it is](https://jekyllrb.com/docs/windows/). As you’ll see, Windows isn’t officially supported, but it works fine on my machine ;)

1.	Next we’ll clone the GIT repo we created earlier: `git clone https://github.com/rvanmaanen/rvanmaanen.github.io.git` in my case. I did this in the directory `/mnt/c/Projects`, so I can access the files from Windows as well without using Ubuntu. All your drives are mounted here by default, so this directory is the same as `C:\Projects`. GIT is available by default in Ubuntu, so no need to install anything.

1.	From the directory containing your GIT repo (again, that would be `/mnt/c/Projects/rvanmaanen.github.io` in my case), execute the command `jekyll new .`, which creates a new blog in your current directory.

1.	Staying in the same directory, run the command `jekyll serve` to spin up a temporary webserver so you can [view your blog locally](http://localhost:4000/)

1.	If everything is working as expected, you can start tracking all the files with GIT, commit them and then push your changes to your remote, before making any more changes. After a few minutes you should see your blog live at `https://username.github.io`.

1.	Have a look at the _config.yml for settings for your blog, like any usernames for your social media, a description, the title and more. I wouldn’t recommend changing the theme at this time, more on that later.

1.	Startup the local webserver again to view your blog, so you can see what your doing in the next steps. Remove the dummy blogpost in the _posts directory and create a new file following the same naming convention (year-month-day-title.md): `2018-04-29-Blogging-with-Jekyll-on-Windows.md`. If you refresh your blog you should see the changes immediately. I use [Notepad++](https://notepad-plus-plus.org/) for this.

1.	To provide a title and give your post a nice layout, place the following in the top of your markdown file: <br/>
\-\--<br/>
layout: post<br/>
title:  "Blogging with Jekyll on Windows"<br/>
categories: jekyll windows<br/>
\-\--<br/>

13.	Start writing, use `jekyll serve` often to see the results and push your changes to GitHub when you’re ready. These are just the basics, there is [a lot you can do with markdown files](https://guides.github.com/features/mastering-markdown/) and [Jekyll](https://jekyllrb.com/docs/).

<br />
# Some other useful stuff:
* Themes - applying and overriding (todo - sorry)
* [Troubleshooting build failures] (https://help.github.com/articles/troubleshooting-github-pages-builds/)

<br />
# A couple other websites I used:
* [GitHub pages](https://pages.github.com/)
* [Viewing Jekyll build error messages](https://help.github.com/articles/viewing-jekyll-build-error-messages/)
* [Using Jekyll as a static site generator with GitHub pages](https://help.github.com/articles/using-jekyll-as-a-static-site-generator-with-github-pages/)
* [Markdown cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
* [Jekyll posts documentation](https://jekyllrb.com/docs/posts/)

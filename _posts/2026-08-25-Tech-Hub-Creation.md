---
layout: "post"
title: "Creating the Tech Hub website"
tags: ["GitHub Copilot", "AI", "Pricing", "Developer Tools", "Organizations", "Workarounds", "Premium Features", "Productivity", "Development Costs", "Enterprise", "Budget", "Feature Limits"]
description: "Series of blogs on the new hub.ms website"
excerpt_separator: "<!--excerpt_end-->"
permalink: "creating-the-tech-hub-website.html"
---

## Topic 1: Creating the website

This blog uses Jekyll and GitHub pages, which is a very popular choice for static websites and allows you to get up and running really fast.
When I created this blog years ago, I was struggling with running Jekyll natively on my Windows machine. I then opted for WSL and succeeded, but today we have devcontainers which is a lot easier.

By adding the following JSON to a file called `devcontainer.json` in a `.devcontainer` folder and then opening that folder with `Visual Studio Code`, you can start working on your own website immediately. The JSON file does a few things:

- Configures the Jekyll devcontainer provided by Microsoft as the container image to use
- It adds support PowerShell (latest version, but you can add configuration to these features)
- It forwards port 4000, so you can access Jekyll on your machine from outside of the container
- It labels the forwarding als 'Jekyll Server'
- A few useful Visual Studio Code extensions are configured
- The "Create Temporary Integrated Console" flag is enabled, which gives you a clean powershell session each time you start debugging. This is really useful when working in pwsh, as it makes sure your latest code is loaded each time you start debugging instead of re-using your previous session. Especially with classes.

```json
{
  "name": "Jekyll",
  "image": "mcr.microsoft.com/devcontainers/jekyll",
  "features": {
    "ghcr.io/devcontainers/features/powershell:1": {}
  },
  "forwardPorts": [
    4000
  ],
  "portsAttributes": {
    "4000": {
      "label": "Jekyll Server"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "DavidAnson.vscode-markdownlint",
        "ms-vscode.powershell",
        "Jekyll.vscode-jekyll-syntax",
        "Jekyll.vscode-jekyll-snippets",
        "ms-python.python",
        "Shopify.theme-check-vscode"
      ],
      "settings": {
        "powershell.debugging.createTemporaryIntegratedConsole": true,
        "terminal.integrated.defaultProfile.linux": "pwsh"
      }
    }
  }
}
```

The most basic version would be this, but the hub.ms website uses quite some PowerShell so I immediately set that up too. The other configuration was also added based on previous experiences.

```json
{
  "name": "Jekyll",
  "image": "mcr.microsoft.com/devcontainers/jekyll"
}
```

Also, it might be wise to set specific versions, to prevent security issues or unexpected bugs/behavior.
# Quarto Setup Guide

## What You Need to Get Started

To use Quarto for PDF generation, you'll need:

1. **Quarto CLI** - The main Quarto application
2. **A LaTeX distribution** - For PDF rendering (tinytex is recommended)
3. **Optional: Python or R** - For executable code chunks

## Installation Steps

### Step 1: Install Quarto

**Option A: Download from official website (Recommended)**
1. Go to https://quarto.org/docs/get-started/
2. Download the Windows installer (.msi file)
3. Run the installer with administrator privileges

**Option B: Using Windows Package Manager (if available)**
```powershell
winget install --id RStudio.quarto
```

### Step 2: Install LaTeX for PDF Support

After installing Quarto, install TinyTeX (a lightweight LaTeX distribution):

```powershell
quarto install tinytex
```

### Step 3: Verify Installation

```powershell
quarto --version
quarto check
```

## Basic Workflow

1. **Create** a `.qmd` file (like the document.qmd I created for you)
2. **Edit** your content using Markdown and code chunks
3. **Render** to PDF using: `quarto render document.qmd --to pdf`

## Your Current Setup

I've created a sample Quarto document (`document.qmd`) in your workspace. Once you install Quarto and TinyTeX, you can render it to PDF using:

```powershell
quarto render document.qmd --to pdf
```

## Troubleshooting

If you encounter issues:
- Make sure you have administrator privileges
- Restart your terminal after installation
- Check your PATH environment variable includes Quarto
- Use `quarto check` to diagnose problems

## Next Steps

1. Install Quarto from the official website
2. Run the installation verification commands
3. Try rendering the sample document I created
4. Customize the document for your needs

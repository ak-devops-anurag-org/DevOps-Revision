
### Windows file path (C:\ak DevOps) while working inside an Ubuntu terminal

```bash
cd /mnt/<drive_letter>/<path_on_pc>

```

So, if your file is on the `D:` drive in a folder called `Projects`, the command would be `cd /mnt/d/Projects`.

*(Note: Always keep the drive letter lowercase inside the Ubuntu terminal, even though Windows uses capital letters like `C:` or `D:`).*

---

### How to locate your Ubuntu path (`/home/akmachine`) in Windows File Explorer

Since you are running WSL, Windows makes it incredibly easy to view your Linux files right inside the native Windows File Explorer. You have two great ways to do this:

#### Method 1: The Terminal Shortcut (Fastest)

While you are inside your Ubuntu terminal at `/home/akmachine`, simply type this command and press Enter:

```bash
explorer.exe .

```

*(Don't forget the dot `.` at the end—it tells Windows to "open the current directory").* This will instantly pop open a standard Windows File Explorer window showing your exact Ubuntu home folder.

#### Method 2: Navigating via File Explorer Sidebar

1. Open **File Explorer** on your Windows PC.
2. Scroll all the way down the left-hand sidebar.
3. You will see a folder icon with a penguin labeled **Linux**.
4. Click **Linux** $\rightarrow$ **Ubuntu** $\rightarrow$ **home** $\rightarrow$ **akmachine**.

You can drag and drop files, copy paths, and edit documents here just like any normal Windows folder!
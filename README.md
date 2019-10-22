# MacOS Directory Sync

Tool designed for keeping a remote directory in sync with a git repository in a local directory.
This is useful for developing code locally and syncing with a web server, similar to WinSCP. Note
that the contents of the entire source directory is synced into the destination directory.  For
example, given the following source directory:

```
source/file1.php
source/file2.php
source/lib/library.php
```

The command ``directory-sync.sh -i -s `pwd` -d /var/www/html`` will result in the following files in
the destination directory:

```
/var/www/html/file1.php
/var/www/html/file2.php
/var/www/html/lib/library.php
```

Based on [boneskull/hook-line-and-syncer](https://gist.github.com/boneskull/6d1fc763fa6da4b53c61).

## Usage

```
directory-sync -s *source-dir* -d *destination** [-i] [-l *log-file*] [-e *excludes-file*] [-r *remote-shell*]
Where:
    -d The destination (local directory or remote location).
    -s The source directory. The contents of the directory will be synced, not the directory itself.
    -r Optional remote shell to use for rsync. Useful for specifying an alternate ssh port.
    -i Perform an initial sync before enabling the file watcher on the source directory.
    -l rsync log file
```

## Examples

Perform an initial sync of the current directory and any subsequent changes to another local
directory:
```
directory-sync.sh -i -s source/ -d /var/www/html
```

Sync only changes to the "source" directory to a remote host

```
directory-sync.sh -s source/ -d remotehost.com:/var/www/html
```

Perform an initial sync of the current directory and any subsequent changes to a remote server:
```
directory-sync.sh -s `pwd` -d remotehost.com:/var/www/html -i
```

Perform an initial sync of the current directory and any subsequent changes to a remote server
using ssh on port 1027:
```
directory-sync.sh -s `pwd` -d remotehost.com:/var/www/html -r 'ssh -p 1027' -i
```

# website_creator
Automatically create folder, database and virtualhost for a website

What this script does:
- Create the website container folder
- Create database with random password
- Create associated virtualhost conf file
- It can create a subfolder

```
Usage: filename FolderName DBName [SubFolder]
If 'SubFolder' is empty 'www' will be used
```

- **filename** is the name of the file to be executed
- **FolderName** is the name of the website folder container
- **DBName** is the name of the database
- **SubFolder** is the "possible" subfolder inside the **FolderName**
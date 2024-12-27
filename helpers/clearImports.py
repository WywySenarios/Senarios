import os
import shutil

def delete_import_files_recursively(folder_path):
    """
    Recursively delete all files with the .import extension in the given folder.

    :param folder_path: Path to the folder to search and delete files.
    """
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".import"):
                file_path = os.path.join(root, file)
                try:
                    os.remove(file_path)
                    print(f"Deleted: {file_path}")
                except Exception as e:
                    print(f"Error deleting {file_path}: {e}")

if __name__ == "__main__":
    current_directory = os.getcwd()
    delete_import_files_recursively(current_directory)


# zcat

`zcat` is a minimalist reimplementation of the Unix `cat` utility, written in Zig. This project is created for learning purposes and offers a streamlined set of features compared to the original `cat` command.

## Features

- **Concatenate Files**: Read files sequentially and output their content to the standard output.
- **Read from Standard Input**: If no files are specified, `zcat` reads from standard input.

## Installation

To build `zcat`, you need to have Zig installed. Follow these steps to install and build the project:

1. Clone the repository:
    ```sh
    git clone https://github.com/ademyanchuk/zcat.git
    cd zcat
    ```

2. Build the project:
    ```sh
    zig build
    ```

3. The compiled executable will be available in `zig-out/bin/`.

## Usage

Run `zcat` with one or more filenames as arguments to concatenate their contents:

```sh
./zcat file1.txt file2.txt
```

If no files are specified, `zcat` reads from standard input:

```sh
./zcat
```

## License

This project is licensed under the MIT License.

---

Feel free to contribute, open issues, and provide feedback to help improve `zcat`. Enjoy using this learning tool!

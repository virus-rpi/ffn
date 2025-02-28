# Formatted Function Names (ffn)

This project provides a tool to convert formatted function names in `.v.ffn` files to standard function names in V. It also includes functionality to watch files or directories for changes and automatically convert them.
These formatted function names are useful for writing more readable code and makes it easier to understand give good names to functions.

## Features

- Convert formatted function names in `.v.ffn` files to standard function names.
- Watch files or directories for changes and automatically convert them.

## Usage

### Command Line

To use the tool from the command line, run:

```sh
ffn [--watch] <file_or_directory1> <file_or_directory2> ...
```

- `--watch`: Optional flag to watch the specified files or directories for changes.
- `<file_or_directory>`: One or more files or directories to convert.

### Example

Convert a single file:

```sh
ffn examples/test_file.v.ffn
```

Convert all files in a directory:

```sh
ffn examples/
```

Watch a file for changes:

```sh
ffn --watch examples/test_file.v.ffn
```

Watch a directory for changes:

```sh
ffn --watch examples/
```

## Example Files

### `examples/useful_example.v.ffn`

```v
module examples

fn abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

fn draw_point_at_{x}_{y}_in_{color}(x int, y int, color string) {
	println('Drawing point at (${x}, ${y}) with color ${color}')
}

fn draw_line_from_{x1}_{y1}_to_{x2}_{y2}_in_{color}(x1 int, y1 int, x2 int, y2 int, color string) {
	dx := x2 - x1
	dy := y2 - y1

	steps := if abs(dx) > abs(dy)  {abs(dx)} else {   abs(dy) }

	if steps == 0 {
		draw_point_at_{x1}_{y1}_in_{color}()
		return
	}

	x_increment := dx / steps
	y_increment := dy / steps

	mut x := x1
	mut y := y1
	for _ in 0..steps {
		draw_point_at_x_y_in_color(int(x), int(y), color)
		x = x + x_increment
		y = y + y_increment
	}
}

fn main() {
	draw_line_from_{0}_{0}_to_{10}_{10}_in_{'red'}()
}
```

### `examples/_ffn_useful_example.v`

```v
module examples

fn abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

fn draw_point_at_x_y_in_color(x int, y int, color string) {
	println('Drawing point at (${x}, ${y}) with color ${color}')
}

fn draw_line_from_x1_y1_to_x2_y2_in_color(x1 int, y1 int, x2 int, y2 int, color string) {
	dx := x2 - x1
	dy := x2 - y1

	steps := if abs(dx) > abs(dy) { abs(dx) } else { abs(dy) }

	if steps == 0 {
		draw_point_at_x_y_in_color(x1, y1, color)
		return
	}

	x_increment := dx / steps
	y_increment := dy / steps

	mut x := x1
	mut y := y1
	for _ in 0 .. steps {
		draw_point_at_x_y_in_color(int(x), int(y), color)
		x = x + x_increment
		y = y + y_increment
	}
}

fn main() {
	draw_line_from_x1_y1_to_x2_y2_in_color(0, 0, 10, 10, 'red')
}
```

## License

This project is licensed under the MIT License.
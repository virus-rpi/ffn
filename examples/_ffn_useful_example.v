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
	dy := y2 - y1

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

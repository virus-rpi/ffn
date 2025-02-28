module examples

fn test_name(name string) {
	println('test called with ${name}')
}

fn meow_nya_mrrp(mrrp string, nya string) {
	println('nya: ${nya}, mrrp: ${mrrp}')
}

fn main() {
	test_name('meow')
	meow_nya_mrrp('2', '1')
}

module main

import os
import regex

fn get_file_content(file_path string) string {
	return os.read_file(file_path) or {
		println('Failed to read file: ${err}')
		return ''
	}
}

fn get_function_names_with_format(content string) []string {
	mut re := regex.regex_opt(r'fn\s+(\w+\{.*\}\w*)\s*\(') or {
		println('Failed to compile regex: ${err}')
		return []
	}

	return re.find_all_str(content)
}

fn reformat_function_names(content string, names []string) string {
	mut new_content := content
	for name in names {
		new_name := name.replace('{', '').replace('}', '').trim(' ')
		new_content = new_content.replace(name, new_name)
	}
	return new_content
}

fn get_usage_regex(matches []string) []string {
	mut regex_list := []string{}
	for m in matches {
		cleaned_match := m.replace('fn', '').replace('(', '').trim(' ')
		mut regex_pattern := regex.regex_opt(r'\{[^(^){\}]*\}') or {
			println('Failed to compile inner regex: ${err}')
			return []
		}
		regex_list << regex_pattern.replace(cleaned_match, r'\{[^(^){\}]*\}') + r'\(\)'
	}

	return regex_list
}

fn find_usages(content string, usage_regex_list []string) []string {
	mut usages := []string{}
	for r in usage_regex_list {
		mut re := regex.regex_opt(r) or {
			println('Failed to compile regex: ${err}')
			return []
		}
		usages << re.find_all_str(content)
	}

	return usages
}

fn get_usage_map(matches []string, content string) map[string]string {
	mut result := map[string]string{}
	for m in matches {
		cleaned := m.replace('fn', '').replace('(', '').trim(' ')
		mut re := regex.regex_opt(r'\{[^(^){\}]*\}') or { continue }
		usage_pattern := re.replace(cleaned, r'\{[^(^){\}]*\}') + r'\(\)'
		mut find_re := regex.regex_opt(usage_pattern) or { continue }
		usages := find_re.find_all_str(content)
		for usage in usages {
			result[usage] = cleaned.replace('{', '').replace('}', '').trim(' ')
		}
	}
	return result
}

fn reformat_usages(content string, usages []string, usage_map map[string]string) string { // TODO: put props in the right order
	mut new_content := content
	for usage in usages {
		mut re := regex.regex_opt(r'\{[^(^){\}]*\}') or {
			println('Failed to compile inner regex: ${err}')
			return ''
		}
		inner_content := re.find_all_str(usage)
		mut props := []string{}
		for prop in inner_content {
			props << prop.replace('{', '').replace('}', '').trim(' ')
		}
		new_usage := usage_map[usage] + '(' + props.join(', ') + ')'
		new_content = new_content.replace(usage, new_usage)
	}

	return new_content
}

fn main() {
	// if os.args.len < 2 {
	//     println('Usage: ./ffn <file_path>')
	//     return
	// }
	// file_path := os.args[1]
	file_path := './test_file.nv'

	content := get_file_content(file_path)
	matches := get_function_names_with_format(content)
	usage_map := get_usage_map(matches, content)
	usage_regex_list := get_usage_regex(matches)
	usages := find_usages(content, usage_regex_list)
	mut new_content := reformat_function_names(content, matches)
	new_content = reformat_usages(new_content, usages, usage_map)
	os.write_file(file_path.replace('.nv', '_generated.v'), new_content) or {
		println('Failed to write file: ${err}')
		return
	}
}

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

fn reformat_usages(content string, usages []string) string {
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
		new_usage := re.replace(usage, '').substr(0, re.replace(usage, '').len - 2) + '(' +
			props.join(', ') + ')'
		new_content = content.replace(usage, new_usage)
	}

	return new_content
}

fn main() {
	// if os.args.len < 2 {
	//     println('Usage: ./ffn <file_path>')
	//     return
	// }
	// file_path := os.args[1]
	//
	file_path := 'test_file.nv'
	content := get_file_content(file_path)
	matches := get_function_names_with_format(content)
	usage_regex_list := get_usage_regex(matches)

	usages := find_usages(content, usage_regex_list)
	new_content := reformat_usages(content, usages)
	println(new_content)
}

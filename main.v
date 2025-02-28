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

struct UsageMapEntry {
	name  string
	props map[int]int // index in {} to index in ()
}

fn get_usage_map(matches []string, content string) map[string]UsageMapEntry {
	mut result := map[string]UsageMapEntry{}
	for m in matches {
		mut real_props_regex := regex.regex_opt(
			m.replace('{', '\\{').replace('}', '\\}').replace('(', '\\(') + r'[^(^){\}]*\)') or {
			println('Failed to compile inner regex: ${err}')
			continue
		}
		mut real_props := real_props_regex.find_all_str(content)[0].replace(m, '').replace(')',
			'').trim(' ').split(',')
		for i, p in real_props {
			real_props[i] = p.trim(' ').split(' ')[0]
		}

		mut re := regex.regex_opt(r'\{[^(^){\}]*\}') or { continue }
		mut placeholders := re.find_all_str(m)
		if placeholders.len != real_props.len {
			println('ERROR: Mismatch between placeholders and props')
			continue
		}
		mut props := map[int]int{}
		for i, mut placeholder in placeholders {
			placeholder = placeholder.replace('{', '').replace('}', '').trim(' ')
			for j, prop in real_props {
				if placeholder == prop {
					props[i] = j
				}
			}
		}
		if props.len != placeholders.len {
			println('ERROR: Failed to match props to placeholders')
			continue
		}

		cleaned := m.replace('fn', '').replace('(', '').trim(' ')
		usage_pattern := re.replace(cleaned, r'\{[^(^){\}]*\}') + r'\(\)'
		mut find_re := regex.regex_opt(usage_pattern) or { continue }
		usages := find_re.find_all_str(content)
		for usage in usages {
			result[usage] = UsageMapEntry{
				name:  cleaned.replace('{', '').replace('}', '').trim(' ')
				props: props
			}
		}
	}
	return result
}

fn reformat_usages(content string, usages []string, usage_map map[string]UsageMapEntry) string {
	mut new_content := content
	for usage in usages {
		mut re := regex.regex_opt(r'\{[^(^){\}]*\}') or {
			println('Failed to compile inner regex: ${err}')
			return ''
		}
		placeholders := re.find_all_str(usage)
		mut props := []string{len: placeholders.len}
		for i, placeholder in placeholders {
			props[usage_map[usage].props[i]] = placeholder.replace('{', '').replace('}',
				'').trim(' ')
		}
		new_usage := usage_map[usage].name + '(' + props.join(', ') + ')'
		new_content = new_content.replace(usage, new_usage)
	}

	return new_content
}

fn save_file(file_path string, content string) {
	base := os.base(file_path).all_before_last('.')
	new_file_path := os.dir(file_path) + os.path_separator + '_' + base + '_ffn.v'
	os.write_file(new_file_path, content) or {
		println('Failed to write file: ${err}')
		return
	}
}

fn formated_function_name_converter(content string) string {
	matches := get_function_names_with_format(content)
	usage_map := get_usage_map(matches, content)
	usage_regex_list := get_usage_regex(matches)
	usages := find_usages(content, usage_regex_list)
	mut new_content := reformat_function_names(content, matches)
	return reformat_usages(new_content, usages, usage_map)
}

fn convert_file(file_path string) {
	content := get_file_content(file_path)
	new_content := formated_function_name_converter(content)
	save_file(file_path, new_content)
}

fn main() {
	if os.args.len < 2 {
		println('Usage: ./ffn <file_path>')
		return
	}
	file_path := os.args[1]

	convert_file(file_path)
}

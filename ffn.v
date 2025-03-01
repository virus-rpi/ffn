module main

import os
import regex
import time

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
	new_file_path := os.dir(file_path) + os.path_separator + '_ffn_' + base.replace('.v.ffn', '.v')
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
	if !file_path.ends_with('.v.ffn') {
		return
	}
	content := get_file_content(file_path)
	new_content := formated_function_name_converter(content)
	save_file(file_path, new_content)
	println('Converted: ${file_path}')
}

fn convert_directory(dir_path string) {
	files := os.ls(dir_path) or {
		println('Failed to list directory: ${err}')
		return
	}
	for file in files {
		full_path := os.join_path(dir_path, file)
		if os.is_file(full_path) {
			convert_file(full_path)
		}
	}
}

fn watch_file(file_path string) {
	if !file_path.ends_with('.v.ffn') {
		return
	}
	mut last_modified := os.file_last_mod_unix(file_path)
	for {
		time.sleep(2 * time.second)
		modified := os.file_last_mod_unix(file_path)
		if modified > last_modified {
			if !os.is_file(file_path) {
				println('Invalid path: ${file_path}, stopping watch on this file...')
				return
			}
			println('Changes detected in "${file_path}", converting...')
			convert_file(file_path)
			last_modified = modified
		}
	}
}

fn watch_path(path string) {
	if os.is_dir(path) {
		files := os.ls(path) or {
			println('Failed to list directory: ${err}')
			return
		}
		for file in files {
			full_path := os.join_path(path, file)
			if os.is_file(full_path) {
				go watch_file(full_path)
			}
		}
	} else if os.is_file(path) {
		go watch_file(path)
	} else {
		println('Invalid path: ${path}')
	}
}

fn main() {
	if os.args.len < 2 {
		println('Usage: ffn [--watch] <file_or_directory1> <file_or_directory2> ...')
		return
	}

	mut watch := false
	mut paths := []string{}
	for arg in os.args[1..] {
		if arg == '--watch' {
			watch = true
		} else {
			paths << arg
		}
	}

	for path in paths {
		if watch {
			go watch_path(path)
		}
		if os.is_dir(path) {
			convert_directory(path)
		} else if os.is_file(path) {
			convert_file(path)
		} else {
			println('Invalid path: ${path}')
		}
	}

	if watch {
		for {
			time.sleep(60 * time.second)
		}
	}
}

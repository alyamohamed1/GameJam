class_name Cipher extends RefCounted
# Pure Caesar helper. Positive shift rotates letters forward (encrypt),
# negative shifts backward (decrypt). Non-letters pass through unchanged.

static func shift(text: String, n: int) -> String:
	var result := ""
	var s := ((n % 26) + 26) % 26
	for i in text.length():
		var c := text[i]
		var code := c.unicode_at(0)
		if code >= 65 and code <= 90:
			result += char(((code - 65 + s) % 26) + 65)
		elif code >= 97 and code <= 122:
			result += char(((code - 97 + s) % 26) + 97)
		else:
			result += c
	return result

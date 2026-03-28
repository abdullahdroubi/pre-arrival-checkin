"""Remove first <style>...</style> and replace <head>...</head> with themed head."""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
name = sys.argv[1]
title = sys.argv[2]
p = root / f"src/main/resources/templates/{name}"
text = p.read_text(encoding="utf-8")
text = re.sub(r"<style>.*?</style>\s*", "", text, count=1, flags=re.DOTALL)
new_head = (
    "<head>\n"
    '    <meta charset="UTF-8">\n'
    '    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
    f"    <title>{title}</title>\n"
    '    <th:block th:replace="~{fragments/checkin-assets :: styles}"></th:block>\n'
    "</head>"
)
text = re.sub(r"<head>.*?</head>", new_head, text, count=1, flags=re.DOTALL)
text = re.sub(r"<html xmlns:th=", '<html lang="en" xmlns:th=', text, count=1)
text = re.sub(r"<body\s*>", '<body class="chk-page">', text, count=1)
text = text.replace(
    '<a class="navbar-brand" href="#" style="color: var(--primary-color); font-weight: bold;">',
    '<a class="navbar-brand" href="#">',
)
text = text.replace(
    '<i class="fas fa-hotel"></i> reterra Property Tech',
    '<i class="fas fa-gem me-2 opacity-75"></i>reterra',
)
text = text.replace(
    '<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>',
    '<th:block th:replace="~{fragments/checkin-assets :: scripts}"></th:block>',
)
p.write_text(text, encoding="utf-8")
print("ok", name)

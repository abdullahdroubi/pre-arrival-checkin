import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
p = root / "src/main/resources/templates/eat.html"
text = p.read_text(encoding="utf-8")

m_style = re.search(r"<style>(.*?)</style>", text, re.DOTALL)
if not m_style:
    raise SystemExit("no style in eat.html")
css = m_style.group(1)
css = re.sub(r"\s*:root\s*\{[^}]*\}\s*", "", css, count=1)
(root / "src/main/resources/static/css/eat-page.css").write_text(css.strip() + "\n", encoding="utf-8")

text = re.sub(r"<style>.*?</style>\s*", "", text, count=1, flags=re.DOTALL)
text = re.sub(
    r"<head>.*?</head>",
    """<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Arrival time · Pre-arrival check-in</title>
    <th:block th:replace="~{fragments/checkin-assets :: styles}"></th:block>
    <link th:href="@{/css/eat-page.css}" rel="stylesheet">
</head>""",
    text,
    count=1,
    flags=re.DOTALL,
)
text = re.sub(r"<body\s*>", '<body class="chk-page">', text, count=1)
text = text.replace(
    '<a class="navbar-brand" href="#" style="color: var(--primary-color); font-weight: bold;">\n                <i class="fas fa-hotel"></i> reterra Property Tech\n            </a>',
    '<a class="navbar-brand" href="#"><i class="fas fa-gem me-2 opacity-75"></i>reterra</a>',
)
text = text.replace(
    '<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>',
    '<th:block th:replace="~{fragments/checkin-assets :: scripts}"></th:block>',
)
text = text.replace("<html xmlns:th=", '<html lang="en" xmlns:th=', 1)
p.write_text(text, encoding="utf-8")
print("ok eat")

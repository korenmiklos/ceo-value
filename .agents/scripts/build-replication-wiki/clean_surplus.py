import pathlib
p = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna/dataset/surplus.md')
t = p.read_text()
start = t.find('The file carries revenue-function-based surplus share fields')
end = t.find('[^make_app]')
if start >= 0 and end > start:
    t = t[:start].rstrip() + '\n\n\n' + t[end:]
    p.write_text(t)
    print('removed span', end - start)
else:
    print('markers', start, end)
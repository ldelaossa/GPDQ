make html
rm -rf ../docs/doctrees
sphinx-build -b rinoh . ../docs/pdf
echo '<meta http-equiv="refresh" content="0; url=html/index.html" />' > ../docs/index.html
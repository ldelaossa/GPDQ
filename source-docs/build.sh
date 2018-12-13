make html
sphinx-build -b rinoh . ../build/pdf
rm -rf ../docs/*
mkdir ../docs
mv ../build/html ../docs
mkdir ../docs/pdf
mv ../build/pdf/*.pdf ../docs/pdf
rm -rf ../build
echo '<meta http-equiv="refresh" content="0; url=html/index.html" />' > ../docs/index.html
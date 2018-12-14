make html
rm -rf ../docs/*
mkdir ../docs
mv ../build/html ../docs
rm -rf ../build
echo '<meta http-equiv="refresh" content="0; url=html/index.html" />' > ../docs/index.html
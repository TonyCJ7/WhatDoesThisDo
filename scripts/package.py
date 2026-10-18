import json
import pathlib
import zipfile

HERE = pathlib.Path(__file__).resolve().parent.parent
manifest = json.loads((HERE / "package.json").read_text())
out = HERE / f"{manifest['name']}-{manifest['version']}.vsix"

VSIX_MANIFEST = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
  <Metadata>
    <Identity Language="en-US" Id="{manifest['name']}" Version="{manifest['version']}" Publisher="{manifest['publisher']}"/>
    <DisplayName>{manifest['displayName']}</DisplayName>
    <Description xml:space="preserve">{manifest['description']}</Description>
    <Categories>Other</Categories>
    <GalleryFlags>Public</GalleryFlags>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{manifest['engines']['vscode']}"/>
      <Property Id="Microsoft.VisualStudio.Code.ExtensionKind" Value="workspace"/>
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code"/>
  </Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
"""

CONTENT_TYPES = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/>
  <Default Extension=".js" ContentType="application/javascript"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>
"""

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as vsix:
    vsix.writestr("extension.vsixmanifest", VSIX_MANIFEST)
    vsix.writestr("[Content_Types].xml", CONTENT_TYPES)

    for name in ("package.json", "extension.js", "parse.js"):
        vsix.write(HERE / name, f"extension/{name}")

print(out)

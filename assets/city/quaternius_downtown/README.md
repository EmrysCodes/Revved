# Quaternius Downtown City MegaKit — Standard

Author: Quaternius. CC0 1.0. Official source: https://quaternius.com/packs/downtowncitymegakit.html
Downloaded from https://quaternius.itch.io/downtown-city-megakit on 2026-10-18.

This is the free Standard glTF kit, not the paid Source project. Original geometry and textures retained; glTF image URIs changed to the shared textures directory. REVVED supplies its own materials, placement, simple collision and road generation. The license is included in LICENSE.txt.

`runtime/` stores compressed copies of the meshes used by the city, with shared texture references. REVVED disables vertex-color-as-albedo because the source uses those channels for wear masks, and enables anisotropic texture filtering. Texture import settings explicitly generate mipmaps; normal textures use normal-map import mode. The paid Source edition's custom window/wear shaders are not included.

@tool
extends RefCounted
func run(plugin:EditorPlugin)->void:
 var tree:=plugin.get_tree();var window:=EditorInterface.get_base_control().get_window();window.mode=Window.MODE_WINDOWED;window.size=Vector2i(1700,1040)
 # Let the native editor finish restoring its previous session before selecting this scene.
 await tree.create_timer(6).timeout
 EditorInterface.open_scene_from_path(plugin.STARTER)
 for i in range(120):await tree.process_frame
 var world:=EditorInterface.get_edited_scene_root()
 if not world or world.scene_file_path!=plugin.STARTER:
  push_error("Preview did not open the regional scene");return
 plugin._show();plugin.hide_bottom_panel();EditorInterface.get_selection().clear()
 for i in range(60):await tree.process_frame
 await RenderingServer.frame_post_draw
 var out:="C:/Users/joshu/Documents/Codex/2026-10-18/referenced-chatgpt-conversation-this-is-an/outputs/REVVED-World-Workshop-editor.png"
 window.get_texture().get_image().save_png(out)
 print("WORKSHOP EDITOR PREVIEW PASS / ",world.scene_file_path)

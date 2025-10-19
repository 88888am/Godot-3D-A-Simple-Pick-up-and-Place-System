shader_type canvas_item;

uniform float width: hint_range(0.0, 10.0);
uniform vec4 color: source_color;

void fragment() {
    vec4 textureColor = texture(TEXTURE, SCREEN_UV, 0.0);
    if (textureColor.a == 0.0){
        bool isFinish = false;
        vec2 screen = width * SCREEN_PIXEL_SIZE;
        for (float x = -screen.x; x <= screen.x && !isFinish; x += SCREEN_PIXEL_SIZE.x) {
            for (float y = -screen.y; y <= screen.y && !isFinish; y += SCREEN_PIXEL_SIZE.y) {
                vec4 textureOutline = texture(TEXTURE, SCREEN_UV + vec2(x, y), 0.0);
                if ( textureOutline.a != 0.0) {
                    COLOR = color;
                    isFinish = true;
                }
            }
        }
        if (!isFinish) {
            COLOR = vec4(0, 0, 0, 0);
        }
    } else {
        COLOR = vec4(0, 0, 0, 0);
    }
}
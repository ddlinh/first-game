shader_type canvas_item;
render_mode unshaded;

// Tầng đĩa thạch. Lưới đi thẳng từ Sim lên GPU dưới dạng texture R8 — mảng
// PackedByteArray của Sim ĐÃ đúng định dạng nên mỗi khung không tốn một phép
// đổi màu nào ở phía CPU; tô màu, viền tiền tuyến và vết thương đều làm ở đây.

uniform sampler2D species_tex : filter_nearest, repeat_disable;
uniform sampler2D hp_tex : filter_nearest, repeat_disable;
uniform float grid_size = 180.0;
uniform float wave_time = 0.0;

// Vàng sáng hơn hẳn hai màu kia nên khi Nhạy cảm chiếm đa số thì cả đĩa chói lên
// và không đọc được gì; hạ độ sáng của nó, kéo hai màu kia lên cho cân mắt.
uniform vec3 col_toxic : source_color = vec3(0.70, 0.38, 0.98);
uniform vec3 col_sensitive : source_color = vec3(0.90, 0.74, 0.26);
uniform vec3 col_resistant : source_color = vec3(0.30, 0.60, 0.99);
uniform vec3 col_agar : source_color = vec3(0.05, 0.09, 0.15);
uniform vec3 col_barrier : source_color = vec3(0.42, 0.45, 0.52);

// Đọc mã chủng của một ô. Byte R nhân 255 rồi làm tròn, đừng ép kiểu thẳng:
// 3.0 lưu trong texture có khi quay về 2.999 và cả ô đổi chủng.
float species_at(vec2 uv) {
	return floor(texture(species_tex, uv).r * 255.0 + 0.5);
}

vec3 tint_of(float s) {
	if (s < 0.5) return col_agar;
	if (s < 1.5) return col_toxic;
	if (s < 2.5) return col_sensitive;
	if (s < 3.5) return col_resistant;
	return col_barrier;
}

void fragment() {
	vec2 uv = UV;
	float s = species_at(uv);

	// Ngoài vành đĩa cũng đánh dấu WALL trong lưới, nhưng phải nhìn ra kính chứ
	// không phải nhựa. Phân biệt bằng khoảng cách tới tâm, khỏi tốn thêm mã chủng.
	float from_center = length(uv - vec2(0.5));
	if (s > 3.5 && from_center > 0.494) {
		discard;
	}

	vec3 col = tint_of(s);
	float alpha = 1.0;

	float texel = 1.0 / grid_size;
	float n0 = species_at(uv + vec2(texel, 0.0));
	float n1 = species_at(uv - vec2(texel, 0.0));
	float n2 = species_at(uv + vec2(0.0, texel));
	float n3 = species_at(uv - vec2(0.0, texel));

	if (s < 0.5) {
		// Thạch trống. Ô trống nằm LẪN trong một quần thể thì tô bằng bản tối của
		// chính chủng đó thay vì đen kịt: mô phỏng luôn có vài phần trăm ô trống rải
		// khắp nơi, để nguyên màu nền thì cả đĩa lấm tấm như hạt tiêu và sóng xoắn
		// ốc chìm nghỉm trong nhiễu.
		float host = max(max(n0, n1), max(n2, n3));
		float agree = float(n0 == host) + float(n1 == host) + float(n2 == host)
			+ float(n3 == host);
		// Ngưỡng 2/4 chứ không phải 3/4: ô trống hay đi thành cụm hai ba ô, mà chỉ cần
		// một hàng xóm cũng trống là số phiếu tụt xuống dưới 3 và lỗ đó lại đen thui.
		if (host > 0.5 && host < 3.5 && agree >= 2.0) {
			col = mix(col, tint_of(host) * 0.42, 0.85);
		} else {
			float grain = sin(uv.x * 90.0 + wave_time * 0.3)
				* sin(uv.y * 74.0 - wave_time * 0.21);
			col += grain * 0.012;
		}
		alpha = 0.94;
	} else if (s < 3.5) {
		// Ô đứng sát chủng KHÁC (không tính ô trống) là tiền tuyến — hắt sáng nhẹ
		// để mắt bám được sóng xoắn ốc đang chạy về đâu. Bản đầu hắt +0.55 và còn
		// nhấp nháy theo thời gian: mọi đường biên hoá thành viền trắng chớp, cả đĩa
		// đọc ra như nhiễu tivi. Sóng xoắn ốc cần MẢNG MÀU LỚN, không cần viền.
		float enemy = float(n0 != s && n0 > 0.5 && n0 < 3.5)
			+ float(n1 != s && n1 > 0.5 && n1 < 3.5)
			+ float(n2 != s && n2 > 0.5 && n2 < 3.5)
			+ float(n3 != s && n3 > 0.5 && n3 < 3.5);
		col = mix(col, col + vec3(0.4), clamp(enemy * 0.25, 0.0, 1.0) * 0.22);

		// Ô sắp chết thì tối đi, nhưng chỉ hơi: Kháng độc có tới 5 máu nên dải rộng
		// biến cả mảng xanh thành năm sắc lốm đốm.
		float max_hp = s < 1.5 ? 2.0 : (s < 2.5 ? 1.0 : 5.0);
		float wound = floor(texture(hp_tex, uv).r * 255.0 + 0.5) / max_hp;
		col *= 0.76 + 0.24 * clamp(wound, 0.0, 1.0);

		// Rìa ngoài quần thể (giáp thạch trống) tối lại, tạo cảm giác khối nổi lên
		// khỏi mặt đĩa thay vì một vũng màu phẳng.
		float voidness = float(n0 < 0.5) + float(n1 < 0.5) + float(n2 < 0.5) + float(n3 < 0.5);
		col *= 1.0 - clamp(voidness * 0.5, 0.0, 1.0) * 0.12;
	} else {
		// Vách nhựa trong lòng đĩa: xám mờ, có sọc để đọc ra là vật cản nhân tạo.
		float stripe = step(0.5, fract((uv.x + uv.y) * grid_size * 0.25));
		col = mix(col * 0.7, col, stripe);
		alpha = 0.95;
	}

	COLOR = vec4(col, alpha);
}

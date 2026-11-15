package com.technicjelle.simple_audio_converter;

import android.os.Build;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
	private static final String CHANNEL = "audio_converter/device";

	@Override
	public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
		super.configureFlutterEngine(flutterEngine);

		new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
			.setMethodCallHandler((call, result) -> {
				if ("info".equals(call.method)) {
					result.success(deviceInfo());
				} else {
					result.notImplemented();
				}
			});
	}

	private Map<String, Object> deviceInfo() {
		Map<String, Object> info = new HashMap<>();

		info.put("manufacturer", safe(Build.MANUFACTURER));
		info.put("brand", safe(Build.BRAND));
		info.put("model", safe(Build.MODEL));
		info.put("device", safe(Build.DEVICE));
		info.put("board", safe(Build.BOARD));
		info.put("hardware", safe(Build.HARDWARE));
		info.put("sdkInt", Build.VERSION.SDK_INT);
		info.put("cores", Runtime.getRuntime().availableProcessors());
		// String[] is not a StandardMessageCodec type. Serialising it directly
		// throws and makes the whole channel call fail, which is how a working
		// device ends up reported as "Unknown / Android 0".
		info.put("abis", TextUtils.join(",", Build.SUPPORTED_ABIS));
		info.put("is64Bit", Build.SUPPORTED_64_BIT_ABIS.length > 0);
		info.put("release", Build.VERSION.RELEASE);
		info.put("incremental", Build.VERSION.INCREMENTAL);
		info.put("securityPatch", Build.VERSION.SECURITY_PATCH);

		// Build.SOC_MODEL exists from API 31. Some vendor builds (notably the
		// first Snapdragon 8 Gen 6 devices) write "0" or an empty string there,
		// so every consumer has to fall back to raw properties.
		info.put("socModel", socModel());
		info.put("socManufacturer", socManufacturer());

		// AOSP / Qualcomm / MediaTek board identifiers.
		info.put("ro.board.platform", prop("ro.board.platform"));
		info.put("ro.soc.model", prop("ro.soc.model"));
		info.put("ro.soc.manufacturer", prop("ro.soc.manufacturer"));
		info.put("ro.hardware", prop("ro.hardware"));
		info.put("ro.boot.hardware", prop("ro.boot.hardware"));
		info.put("ro.chipname", prop("ro.chipname"));
		info.put("ro.hardware.chipname", prop("ro.hardware.chipname"));
		info.put("ro.mediatek.platform", prop("ro.mediatek.platform"));
		info.put("ro.product.board", prop("ro.product.board"));
		info.put("ro.product.cpu.abi", prop("ro.product.cpu.abi"));
		info.put("ro.build.version.release", Build.VERSION.RELEASE);

		// Qualcomm vendor props: different generations of the same ROM expose
		// different names, and some only carry these after early boot.
		info.put("ro.vendor.qti.soc_model", prop("ro.vendor.qti.soc_model"));
		info.put("ro.vendor.qti.soc_name", prop("ro.vendor.qti.soc_name"));
		info.put("ro.qti.soc_model", prop("ro.qti.soc_model"));
		info.put("ro.qti.soc_name", prop("ro.qti.soc_name"));

		// ROM identity: HyperOS, MIUI, ColorOS, OriginOS, and the generic
		// incremental string for everything else (Pixel, Samsung, Nothing…).
		info.put("ro.mi.os.version.name", prop("ro.mi.os.version.name"));
		info.put("ro.miui.ui.version.name", prop("ro.miui.ui.version.name"));
		info.put("ro.oppo.version", prop("ro.oppo.version"));
		info.put("ro.realme.ui.version", prop("ro.realme.ui.version"));
		info.put("ro.vivo.os.version", prop("ro.vivo.os.version"));
		info.put("ro.build.version.incremental", Build.VERSION.INCREMENTAL);
		info.put("ro.product.system.name", prop("ro.product.system.name"));
		info.put("ro.product.marketname", prop("ro.product.marketname"));
		info.put("ro.product.model", prop("ro.product.model"));
		info.put("ro.product.vendor.model", prop("ro.product.vendor.model"));
		info.put("ro.product.odm.model", prop("ro.product.odm.model"));
		info.put("ro.build.characteristics", prop("ro.build.characteristics"));
		info.put("ro.build.display.id", prop("ro.build.display.id"));

		// Last-resort sources that do not depend on hidden system properties.
		info.put("proc.cpuinfo.hardware", cpuInfoValue("Hardware"));
		info.put("proc.deviceTree.model", readSmallFile("/proc/device-tree/model"));
		info.put("proc.soc0.machine", readSmallFile("/sys/devices/soc0/machine"));
		info.put("proc.soc0.socId", readSmallFile("/sys/devices/soc0/soc_id"));
		info.put("proc.soc0.family", readSmallFile("/sys/devices/soc0/family"));

		return info;
	}

	private String socModel() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			try {
				return safe(Build.SOC_MODEL);
			} catch (Throwable ignored) {
				return null;
			}
		}
		return null;
	}

	private String socManufacturer() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			try {
				return safe(Build.SOC_MANUFACTURER);
			} catch (Throwable ignored) {
				return null;
			}
		}
		return null;
	}

	private static String safe(String value) {
		if (value == null) return null;
		String trimmed = value.trim();
		if (trimmed.isEmpty() || "unknown".equalsIgnoreCase(trimmed)) return null;
		return trimmed;
	}

	private static String prop(String key) {
		String reflected = propReflect(key);
		if (reflected != null) return reflected;
		return shellProps().get(key);
	}

	private static String propReflect(String key) {
		try {
			Class<?> clazz = Class.forName("android.os.SystemProperties");
			Method get = clazz.getMethod("get", String.class);
			Object value = get.invoke(null, key);
			return value instanceof String ? safe((String) value) : null;
		} catch (Throwable ignored) {
			return null;
		}
	}

	private static volatile Map<String, String> cachedShellProps;

	/** `getprop` still works when the hidden SystemProperties API is blocked. */
	private static Map<String, String> shellProps() {
		Map<String, String> cached = cachedShellProps;
		if (cached != null) return cached;
		Map<String, String> parsed = new HashMap<>();
		try {
			Process process = new ProcessBuilder("/system/bin/getprop").start();
			BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
			String line;
			while ((line = reader.readLine()) != null) {
				// `getprop` prints "[key]: [value]"; a few vendor builds use
				// plain key=value. Accept both instead of silently returning
				// an empty map on the format that actually ships.
				int bracket = line.indexOf("]: [");
				if (line.startsWith("[") && bracket > 0) {
					String key = line.substring(1, bracket).trim();
					String value = line.substring(bracket + 4).trim();
					if (value.endsWith("]")) value = value.substring(0, value.length() - 1);
					if (!key.isEmpty()) parsed.put(key, value);
				} else {
					int eq = line.indexOf('=');
					if (eq > 0) parsed.put(line.substring(0, eq).trim(), line.substring(eq + 1).trim());
				}
			}
			reader.close();
			process.waitFor(1200, TimeUnit.MILLISECONDS);
		} catch (Throwable ignored) {
			// Keep whatever was parsed before the failure.
		}
		cachedShellProps = parsed;
		return parsed;
	}

	private static String cpuInfoValue(String field) {
		try (BufferedReader reader = new BufferedReader(new FileReader("/proc/cpuinfo"))) {
			String line;
			while ((line = reader.readLine()) != null) {
				int colon = line.indexOf(':');
				if (colon > 0 && line.substring(0, colon).trim().equalsIgnoreCase(field)) {
					return safe(line.substring(colon + 1));
				}
			}
		} catch (Throwable ignored) {
			// Not every kernel exposes a readable cpuinfo.
		}
		return null;
	}

	private static String readSmallFile(String path) {
		try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
			String line = reader.readLine();
			return safe(line);
		} catch (Throwable ignored) {
			return null;
		}
	}
}

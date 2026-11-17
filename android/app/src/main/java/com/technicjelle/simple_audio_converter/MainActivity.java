package com.technicjelle.simple_audio_converter;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.DocumentsContract;
import android.provider.OpenableColumns;
import android.text.TextUtils;
import android.webkit.MimeTypeMap;

import androidx.annotation.NonNull;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
	private static final String CHANNEL = "audio_converter/device";
	private static final String OUTPUT_CHANNEL = "timbre/output";
	private static final String PROGRESS_CHANNEL = "timbre/progress";
	private static final int REQUEST_OUTPUT_TREE = 0x544D;
	private static final int REQUEST_NOTIFICATIONS = 0x544E;
	private static final String OUTPUT_PREFS = "timbre_output";
	private static final String KEY_TREE_URI = "tree_uri";
	private static final String KEY_TREE_NAME = "tree_name";

	private MethodChannel.Result pendingOutputResult;

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

		new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), OUTPUT_CHANNEL)
			.setMethodCallHandler((call, result) -> {
				switch (call.method) {
					case "current":
						result.success(storedTarget());
						break;
					case "choose":
						chooseOutputTree(result);
						break;
					case "clear":
						result.success(clearOutputTree());
						break;
					case "publish":
						Map<?, ?> args = call.arguments instanceof Map ? (Map<?, ?>) call.arguments : null;
						String path = args != null && args.get("path") instanceof String
							? (String) args.get("path")
							: null;
						publishFile(path, result);
						break;
					default:
						result.notImplemented();
				}
			});

		new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PROGRESS_CHANNEL)
			.setMethodCallHandler((call, result) -> {
				Map<?, ?> args = call.arguments instanceof Map ? (Map<?, ?>) call.arguments : null;
				String title = stringArg(args, "title", "Timbre");
				String text = stringArg(args, "text", "");
				int progress = intArg(args, "progress", 0);
				switch (call.method) {
					case "start":
						ensureNotificationPermission();
						ProgressService.start(this, title, text);
						result.success(true);
						break;
					case "update":
						ProgressService.update(this, title, text, progress);
						result.success(true);
						break;
					case "stop":
						ProgressService.stop(this);
						result.success(true);
						break;
					default:
						result.notImplemented();
				}
			});
	}

	private String stringArg(Map<?, ?> args, String key, String fallback) {
		if (args == null) return fallback;
		Object value = args.get(key);
		return value instanceof String ? (String) value : fallback;
	}

	private int intArg(Map<?, ?> args, String key, int fallback) {
		if (args == null) return fallback;
		Object value = args.get(key);
		return value instanceof Number ? ((Number) value).intValue() : fallback;
	}

	private void ensureNotificationPermission() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return;
		if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
			== PackageManager.PERMISSION_GRANTED) return;
		requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, REQUEST_NOTIFICATIONS);
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

	private SharedPreferences outputPrefs() {
		return getSharedPreferences(OUTPUT_PREFS, Context.MODE_PRIVATE);
	}

	private Map<String, Object> storedTarget() {
		SharedPreferences prefs = outputPrefs();
		String uri = prefs.getString(KEY_TREE_URI, null);
		if (uri == null || uri.isEmpty()) return null;
		String name = prefs.getString(KEY_TREE_NAME, null);
		if (name == null || name.isEmpty()) name = displayName(Uri.parse(uri));
		return targetMap(uri, name);
	}

	private Map<String, Object> targetMap(String uri, String name) {
		Map<String, Object> map = new HashMap<>();
		map.put("uri", uri);
		map.put("name", name == null || name.isEmpty() ? "Output folder" : name);
		return map;
	}

	private void chooseOutputTree(MethodChannel.Result result) {
		if (pendingOutputResult != null) {
			result.error("busy", "The folder picker is already open.", null);
			return;
		}
		Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
		intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION
			| Intent.FLAG_GRANT_WRITE_URI_PERMISSION
			| Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
			| Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
		pendingOutputResult = result;
		try {
			startActivityForResult(intent, REQUEST_OUTPUT_TREE);
		} catch (Exception e) {
			pendingOutputResult = null;
			result.error("picker", e.getMessage(), null);
		}
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		if (requestCode != REQUEST_OUTPUT_TREE) return;
		MethodChannel.Result result = pendingOutputResult;
		pendingOutputResult = null;
		if (result == null) return;
		if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
			result.success(null);
			return;
		}
		Uri tree = data.getData();
		int flags = data.getFlags()
			& (Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
		try {
			getContentResolver().takePersistableUriPermission(tree, flags);
		} catch (SecurityException e) {
			result.error("permission", "The system did not keep write access to this folder.", null);
			return;
		}
		String name = displayName(tree);
		outputPrefs().edit()
			.putString(KEY_TREE_URI, tree.toString())
			.putString(KEY_TREE_NAME, name)
			.apply();
		result.success(targetMap(tree.toString(), name));
	}

	private boolean clearOutputTree() {
		String stored = outputPrefs().getString(KEY_TREE_URI, null);
		if (stored != null && !stored.isEmpty()) {
			Uri tree = Uri.parse(stored);
			try {
				getContentResolver().releasePersistableUriPermission(
					tree,
					Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
				);
			} catch (SecurityException ignored) {
				// The grant may already be gone; removing the preference is enough.
			}
		}
		outputPrefs().edit().remove(KEY_TREE_URI).remove(KEY_TREE_NAME).apply();
		return true;
	}

	private void publishFile(String path, MethodChannel.Result result) {
		if (path == null || path.isEmpty()) {
			result.error("path", "Missing local file path.", null);
			return;
		}
		Map<String, Object> target = storedTarget();
		if (target == null) {
			result.error("folder", "No output folder is selected.", null);
			return;
		}
		File source = new File(path);
		if (!source.isFile()) {
			result.error("file", "The converted file is gone.", null);
			return;
		}
		Uri tree = Uri.parse((String) target.get("uri"));
		Uri parent = treeDocumentUri(tree);
		Uri destination = null;
		try {
			String name = uniqueName(tree, parent, source.getName());
			String mime = mimeFor(name);
			destination = DocumentsContract.createDocument(
				getContentResolver(), parent, mime, name
			);
			if (destination == null) {
				result.error("create", "The folder refused a new file.", null);
				return;
			}
			ContentResolver resolver = getContentResolver();
			try (InputStream in = new FileInputStream(source);
				 OutputStream out = resolver.openOutputStream(destination)) {
				if (out == null) throw new IllegalStateException("No write stream.");
				byte[] buffer = new byte[8192];
				int read;
				while ((read = in.read(buffer)) != -1) {
					out.write(buffer, 0, read);
				}
				out.flush();
			}
			String writtenName = displayName(destination);
			Map<String, Object> map = new HashMap<>();
			map.put("uri", destination.toString());
			map.put("name", writtenName);
			result.success(map);
		} catch (Exception e) {
			if (destination != null) {
				try {
					DocumentsContract.deleteDocument(getContentResolver(), destination);
				} catch (Exception ignored) {}
			}
			result.error("copy", e.getMessage(), null);
		}
	}

	private Uri treeDocumentUri(Uri tree) {
		return DocumentsContract.buildDocumentUriUsingTree(
			tree, DocumentsContract.getTreeDocumentId(tree)
		);
	}

	private String displayName(Uri uri) {
		try {
			Uri document = DocumentsContract.isDocumentUri(this, uri)
				? uri
				: DocumentsContract.buildDocumentUriUsingTree(
					uri, DocumentsContract.getTreeDocumentId(uri)
				);
			try (Cursor cursor = getContentResolver().query(
				document, new String[]{OpenableColumns.DISPLAY_NAME},
				null, null, null
			)) {
				if (cursor != null && cursor.moveToFirst()) {
					int index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
					if (index >= 0) {
						String value = cursor.getString(index);
						if (value != null && !value.trim().isEmpty()) return value.trim();
					}
				}
			}
		} catch (Exception ignored) {}
		String last = uri.getLastPathSegment();
		return last == null || last.isEmpty() ? "Output folder" : last;
	}

	private String uniqueName(Uri tree, Uri parent, String name) {
		Set<String> existing = new HashSet<>();
		Uri children = DocumentsContract.buildChildDocumentsUriUsingTree(
			tree, DocumentsContract.getTreeDocumentId(tree)
		);
		try (Cursor cursor = getContentResolver().query(
			children, new String[]{DocumentsContract.Document.COLUMN_DISPLAY_NAME},
			null, null, null
		)) {
			if (cursor != null) {
				while (cursor.moveToNext()) {
					String child = cursor.getString(0);
					if (child != null) existing.add(child.toLowerCase());
				}
			}
		} catch (Exception ignored) {}
		if (!existing.contains(name.toLowerCase())) return name;
		int dot = name.lastIndexOf('.');
		String stem = dot > 0 ? name.substring(0, dot) : name;
		String extension = dot > 0 ? name.substring(dot) : "";
		for (int n = 2; n < 10000; n++) {
			String candidate = stem + " (" + n + ")" + extension;
			if (!existing.contains(candidate.toLowerCase())) return candidate;
		}
		return stem + " (" + System.currentTimeMillis() + ")" + extension;
	}

	private String mimeFor(String name) {
		int dot = name.lastIndexOf('.');
		if (dot > 0) {
			String extension = name.substring(dot + 1).toLowerCase();
			String mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
			if (mime != null && !mime.isEmpty()) return mime;
		}
		return "application/octet-stream";
	}
}

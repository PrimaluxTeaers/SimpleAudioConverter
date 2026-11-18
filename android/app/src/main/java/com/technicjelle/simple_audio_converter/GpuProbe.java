package com.technicjelle.simple_audio_converter;

import android.content.Context;
import android.content.pm.ConfigurationInfo;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.GLES20;
import android.app.ActivityManager;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

/** Reads the actual GL renderer instead of guessing from the CPU model. */
public final class GpuProbe {
	private GpuProbe() {}

	public static Map<String, Object> read(Context context) {
		Map<String, Object> out = new HashMap<>();
		out.put("renderer", "");
		out.put("vendor", "");
		out.put("version", "");
		out.put("eglVendor", "");
		out.put("eglVersion", "");
		out.put("glEsVersion", "");
		out.put("source", "unavailable");

		EGLDisplay display = EGL14.EGL_NO_DISPLAY;
		EGLContext eglContext = EGL14.EGL_NO_CONTEXT;
		EGLSurface surface = EGL14.EGL_NO_SURFACE;
		try {
			display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
			if (display == EGL14.EGL_NO_DISPLAY) throw new IllegalStateException("no EGL display");
			int[] majorMinor = new int[2];
			if (!EGL14.eglInitialize(display, majorMinor, 0, majorMinor, 1)) {
				throw new IllegalStateException("eglInitialize failed");
			}
			int[] configAttribs = new int[]{
				EGL14.EGL_RED_SIZE, 8,
				EGL14.EGL_GREEN_SIZE, 8,
				EGL14.EGL_BLUE_SIZE, 8,
				EGL14.EGL_ALPHA_SIZE, 8,
				EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
				EGL14.EGL_SURFACE_TYPE, EGL14.EGL_PBUFFER_BIT,
				EGL14.EGL_NONE
			};
			EGLConfig[] configs = new EGLConfig[1];
			int[] configCount = new int[1];
			if (!EGL14.eglChooseConfig(display, configAttribs, 0, configs, 0, 1, configCount, 0)
				|| configCount[0] < 1) {
				throw new IllegalStateException("no EGL config");
			}
			int[] contextAttribs = new int[]{
				EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
				EGL14.EGL_NONE
			};
			eglContext = EGL14.eglCreateContext(display, configs[0], EGL14.EGL_NO_CONTEXT, contextAttribs, 0);
			if (eglContext == null || eglContext == EGL14.EGL_NO_CONTEXT) {
				throw new IllegalStateException("eglCreateContext failed");
			}
			int[] surfaceAttribs = new int[]{
				EGL14.EGL_WIDTH, 1,
				EGL14.EGL_HEIGHT, 1,
				EGL14.EGL_NONE
			};
			surface = EGL14.eglCreatePbufferSurface(display, configs[0], surfaceAttribs, 0);
			if (surface == null || surface == EGL14.EGL_NO_SURFACE) {
				throw new IllegalStateException("eglCreatePbufferSurface failed");
			}
			if (!EGL14.eglMakeCurrent(display, surface, surface, eglContext)) {
				throw new IllegalStateException("eglMakeCurrent failed");
			}
			out.put("renderer", safe(GLES20.glGetString(GLES20.GL_RENDERER)));
			out.put("vendor", safe(GLES20.glGetString(GLES20.GL_VENDOR)));
			out.put("version", safe(GLES20.glGetString(GLES20.GL_VERSION)));
			out.put("eglVendor", safe(EGL14.eglQueryString(display, EGL14.EGL_VENDOR)));
			out.put("eglVersion", safe(EGL14.eglQueryString(display, EGL14.EGL_VERSION)));
			out.put("source", "egl");
		} catch (Throwable ignored) {
			out.put("source", "egl-failed");
		} finally {
			try { EGL14.eglMakeCurrent(display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT); } catch (Throwable ignored) {}
			try { if (surface != null && surface != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(display, surface); } catch (Throwable ignored) {}
			try { if (eglContext != null && eglContext != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(display, eglContext); } catch (Throwable ignored) {}
			try { if (display != EGL14.EGL_NO_DISPLAY) EGL14.eglTerminate(display); } catch (Throwable ignored) {}
		}

		try {
			ActivityManager manager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
			ConfigurationInfo info = manager.getDeviceConfigurationInfo();
			out.put("glEsVersion", safe(info.getGlEsVersion()));
		} catch (Throwable ignored) {}
		if (safe((String) out.get("renderer")).isEmpty()) {
			String prop = prop("ro.hardware.egl");
			if (prop != null && !prop.isEmpty()) {
				out.put("renderer", prop);
				out.put("source", "ro.hardware.egl");
			}
		}
		return out;
	}

	private static String safe(String value) {
		return value == null ? "" : value.trim();
	}

	private static String prop(String key) {
		try {
			Class<?> clazz = Class.forName("android.os.SystemProperties");
			Method get = clazz.getMethod("get", String.class);
			Object value = get.invoke(null, key);
			return value instanceof String ? safe((String) value) : null;
		} catch (Throwable ignored) {
			return null;
		}
	}
}

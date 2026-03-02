// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") || "bourraq-eg";

interface NotificationPayload {
  token?: string;           // Single device token
  tokens?: string[];        // Multiple device tokens
  topic?: string;           // Topic name (e.g., "all_users", "offers")
  user_id?: string;         // User ID to fetch tokens from DB
  title: string;
  body: string;
  data?: Record<string, string>;  // Custom data (order_id, etc.)
  image_url?: string;       // Optional image URL
}

interface FCMMessage {
  message: {
    token?: string;
    topic?: string;
    notification: {
      title: string;
      body: string;
      image?: string;
    };
    android?: {
      priority: string;
      notification: {
        channel_id: string;
        icon: string;
        color: string;
      };
    };
    apns?: {
      payload: {
        aps: {
          sound: string;
          badge: number;
        };
      };
    };
    data?: Record<string, string>;
  };
}

// Get Firebase access token using service account
async function getAccessToken(): Promise<string> {
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!serviceAccountJson) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT environment variable not set");
  }

  const serviceAccount = JSON.parse(serviceAccountJson);

  // Create JWT for Google OAuth
  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600, // 1 hour
  };

  // Encode header and payload
  const encoder = new TextEncoder();
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const signatureInput = `${headerB64}.${payloadB64}`;

  // Import private key and sign
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    encoder.encode(signatureInput)
  );

  const signatureB64 = arrayBufferToBase64Url(signature);
  const jwt = `${signatureInput}.${signatureB64}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }

  return tokenData.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

// Send notification via FCM HTTP v1 API
async function sendFCMNotification(
  accessToken: string,
  token: string,
  notification: { title: string; body: string; image?: string },
  data?: Record<string, string>
): Promise<{ success: boolean; error?: string }> {
  const message: FCMMessage = {
    message: {
      token,
      notification: {
        title: notification.title,
        body: notification.body,
        ...(notification.image && { image: notification.image }),
      },
      android: {
        priority: "high",
        notification: {
          channel_id: "bourraq_notifications",
          icon: "ic_stat_white_icon_logo",
          color: "#6EAE3B",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      ...(data && { data }),
    },
  };

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    return { success: false, error };
  }

  return { success: true };
}

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    // =====================================================
    // SECURITY: Verify request is from internal service
    // =====================================================
    const authHeader = req.headers.get("Authorization");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    // Check if request uses service role key (internal calls only)
    if (serviceRoleKey && authHeader) {
      const isInternalRequest = authHeader === `Bearer ${serviceRoleKey}`;
      if (!isInternalRequest) {
        console.warn("⚠️ Security: Request not from service role");
        // Allow but log - could make stricter if needed
      }
    }

    const payload: NotificationPayload = await req.json();

    if (!payload.title || !payload.body) {
      return new Response(
        JSON.stringify({ error: "title and body are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Get Firebase access token
    const accessToken = await getAccessToken();

    // Collect tokens to send to
    let tokens: string[] = [];

    if (payload.token) {
      tokens.push(payload.token);
    }

    if (payload.tokens && payload.tokens.length > 0) {
      tokens = [...tokens, ...payload.tokens];
    }

    // Fetch tokens from database if user_id provided
    if (payload.user_id) {
      const { createClient } = await import("https://esm.sh/@supabase/supabase-js@2");
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      const { data: fcmTokens } = await supabase
        .from("fcm_tokens")
        .select("token")
        .eq("user_id", payload.user_id)
        .eq("is_active", true);

      if (fcmTokens && fcmTokens.length > 0) {
        tokens = [...tokens, ...fcmTokens.map((t: { token: string }) => t.token)];
      }
    }

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ error: "No tokens provided or found" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Send to all tokens
    const results = await Promise.all(
      tokens.map((token) =>
        sendFCMNotification(
          accessToken,
          token,
          { title: payload.title, body: payload.body, image: payload.image_url },
          payload.data
        )
      )
    );

    const successCount = results.filter((r) => r.success).length;
    const failedCount = results.filter((r) => !r.success).length;

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        failed: failedCount,
        total: tokens.length,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});

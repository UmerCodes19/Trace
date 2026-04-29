const admin = require('firebase-admin');
const supabase = require('../utils/supabase');

class NotificationService {
  /**
   * Sends a push notification to a specific user and saves it to the database
   * @param {string} userId - Target user ID
   * @param {Object} payload - { title, body, data, type }
   */
  static async sendToUser(userId, payload) {
    console.log(`[NotificationService] Triggered for user ${userId}:`, payload.title);
    try {
      // 1. Save to Database (In-app notification)
      const { error: dbError } = await supabase
        .from('notifications')
        .insert({
          user_id: userId,
          title: payload.title,
          body: payload.body,
          type: payload.type || 'general',
          data: payload.data || {},
          is_read: false,
          timestamp: Date.now()
        });

      if (dbError) {
        console.error('[NotificationService] DB Error:', dbError);
      } else {
        console.log('[NotificationService] Saved to DB successfully');
      }

      // 2. Get user's FCM token for Push Notification
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('fcm_token, chatNotificationsEnabled, proximityAlertsEnabled')
        .eq('uid', userId)
        .single();

      if (userError || !user) {
        console.error(`[NotificationService] User Lookup Error for ${userId}:`, userError);
        return;
      }

      if (!user.fcm_token) {
        console.warn(`[NotificationService] No token found for user ${userId}. Skipping push.`);
        return;
      }

      console.log(`[NotificationService] Found token for ${userId}, preparing FCM message...`);

      // Check user preferences if applicable
      if (payload.type === 'chat' && user.chatNotificationsEnabled === false) {
        console.log('[NotificationService] Chat notifications disabled for this user. Skipping push.');
        return;
      }

      // 3. Prepare message
      const message = {
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data || {},
        token: user.fcm_token,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'trace_notifications',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      // 4. Send via FCM
      const response = await admin.messaging().send(message);
      console.log(`[NotificationService] FCM Success for ${userId}:`, response);
      return response;
    } catch (error) {
      console.error(`[NotificationService] FATAL ERROR for user ${userId}:`, error);
      
      // Handle invalid tokens
      if (error.code === 'messaging/registration-token-not-registered') {
        console.log(`Removing invalid token for user ${userId}`);
        await supabase
          .from('users')
          .update({ fcm_token: null })
          .eq('uid', userId);
      }
    }
  }

  /**
   * Broadcast notification to multiple users
   */
  static async broadcastToAll(payload) {
    const { data: users } = await supabase
      .from('users')
      .select('uid');

    if (users) {
      await Promise.all(users.map(u => this.sendToUser(u.uid, payload)));
    }
  }

  /**
   * Broadcast notification to specific role
   */
  static async broadcastToRole(role, payload) {
    const { data: users } = await supabase
      .from('users')
      .select('uid')
      .eq('role', role);

    if (users) {
      await Promise.all(users.map(u => this.sendToUser(u.uid, payload)));
    }
  }
}

module.exports = NotificationService;

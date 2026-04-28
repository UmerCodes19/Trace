const admin = require('firebase-admin');
const supabase = require('../utils/supabase');

class NotificationService {
  /**
   * Sends a push notification to a specific user
   * @param {string} userId - Target user ID
   * @param {Object} payload - { title, body, data }
   */
  static async sendToUser(userId, payload) {
    try {
      // 1. Get user's FCM token
      const { data: user, error } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('uid', userId)
        .single();

      if (error || !user || !user.fcm_token) {
        console.warn(`Skipping notification: No token found for user ${userId}`);
        return;
      }

      // 2. Prepare message
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

      // 3. Send via FCM
      const response = await admin.messaging().send(message);
      console.log(`Notification sent to ${userId}:`, response);
      return response;
    } catch (error) {
      console.error(`FCM Error for user ${userId}:`, error);
      
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
   * Broadcast notification to multiple users (e.g., all admins)
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

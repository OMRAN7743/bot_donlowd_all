import sqlite3
import telebot
import os
import time
import datetime
import kvsqlite
from telebot import types
from telebot.types import InlineKeyboardButton, InlineKeyboardMarkup
import requests
from bs4 import BeautifulSoup
import io
import re

TOKEN = "8284694498:AAF4f5jma_Dp-GaKFR_Cvar0yfh73QnKBIk"

# ✅ الأدمن الوحيد
ADMIN_IDS = [5559869840]

# ملاحظة هامة : يمنع بيع الملف او تغيير حقوقة او اعادة نشرة دون ذكر مصدر القناة الاساسي
# مطور الملف : @RR8R9
# قناة الملفات : https://t.me/+X0d_nc22x9o0M2Yy

bot = telebot.TeleBot(TOKEN, num_threads=20, skip_pending=True)
db = kvsqlite.sync.Client('users.sqlite', 'users')
user_states = {}

if not db.exists("banned_users"):
    db.set("banned_users", [])
if not db.exists("force_subscribe_channels"):
    db.set("force_subscribe_channels", [])
if not db.exists("user_ids"):
    db.set("user_ids", [])

# ✅ تم إلغاء الاشتراك الإجباري نهائياً (لا تثبيت لقناة ولا فحص اشتراك)
db.set("force_subscribe_channels", [])

LANGUAGES = {
    'ar': {
        'welcome': "👋🏻┇أهلاً بك عزيزي في بوت التحميل من جميع مواقع التواصل الاجتماعي.\n\n"
                   "- من خلال البوت يمكنك تحميل الفيديوهات والصوتيات من أشهر المنصات العالمية وبجودة عالية.\n"
                   "- المنصات التي يشرحها قسم المساعدة: ( يوتيوب، انستقرام، فيسبوك، تويتر، تيك توك، بينترست، سناب شات ).",
        'banned': "أنت محظور من استخدام هذا البوت .",
        'subscribe_first': "عليك الاشتراك بالقناة أشترك ثم ارسل /start\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯",
        'searching': "- جار تحليل الرابط ...",
        'downloading': "جار التحميل ...",
        'error_general': "حدث خطأ .",
        'error_link': "حدث خطأ، يرجى التأكد من أن الرابط صحيح.",
        'how_to_use_button': "⦗ طريقة الأستخدام ⦘",
        'change_lang_button': "⦗ اللغة ⦘",
        'how_to_use_text': "أهلاً بك في قسم المساعدة، من خلال هذا البوت يمكنك التحميل من جميع أقسام مواقع التواصل الاجتماعي وكل منصة أدناه :\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ يوتيوب ﹞\n"
                           " - يمكنك تحميل الفيديو والصوتيات من تطبيق اليوتيوب عبر رابط الأغنية/الفيديو من اليوتيوب فقط.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ انستقرام ﹞\n"
                           " - يمكنك تحميل الريلز والستوريات من تطبيق الانستقرام عبر ارسال الرابط فقط.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ فيسبوك ﹞\n"
                           " - يمكنك تحميل الفيديو من تطبيق الفيسبوك عن طريق أرسال رابط الفيديو فقط.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ بينترست ﹞\n"
                           " - يمكنك تحميل الفيديو من تطبيق بينترست عن طريق أرسال رابط الفيديو فقط.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ تويتر ﹞\n"
                           " - يمكنك تحميل الفيديو من تطبيق تويتر (X)، عن طريق أرسال رابط التغريدة فقط.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ تيك توك ﹞\n"
                           " - يمكنك تحميل الفيديو والصوتيات من تطبيق التيك توك عن طريق أرسال رابط الفيديو فقط.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ سناب شات ﹞\n"
                           " - يمكنك تحميل الفيديو من سناب شات إذا كان الرابط عامًا/قابل للفتح من المتصفح (Spotlight أو رابط مشاركة عام).\n"
                           " - فقط أرسل رابط السناب مباشرة للبوت.\n",
        'back_button': "⦗ رجوع ⦘",
        'choose_lang': "اختر لغتك:",
        'lang_changed': "تم تغيير اللغة بنجاح.",
        'admin_panel_title': "- أهلا عزيزي المطور الأساسي .\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ \n- اختر ماتريد فعلة من الأزرار ادناه :",
        'admin_panel_back': "- أهلا بك عزيزي المطور الأساسي .\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ \n- يمكنك التحكم عبر الأزرار ادناه .",
        'admin_broadcast': "⦗ إذاعة ⦘",
        'send_broadcast': "أرسل لي الإذاعة .",
        'admin_ban': "⦗ حظر عضو ⦘",
        'send_id': "أرسل لي الأيدي .",
        'admin_unban': "⦗ إلغاء حظر ⦘",
        'admin_stats': "⦗ إحصائيات البوت ⦘",
        'stats_title': "- إحصائيات البوت\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ \n",
        'stats_users': "• **عدد المستخدمين:**",
        'stats_new': "• **المستخدمين الجدد (اخر 24 ساعة):**",
        'stats_active': "• **المستخدمين النشطين (اخر 7 أيام):**",
        'stats_banned': "• **عدد المحظورين :**",
        'wait': "- انتضر ...",
        'update_button': "⦗ تحديث ⦘",
        'ban_success': "- تم حظر العضو بنجاح .",
        'ban_already': "- هذا العضو محظور بالفعل .",
        'ban_invalid_id': "- يجب ارسال ايدي عضو صحيح .",
        'unban_success': "- تم إلغاء حظر العضو بنجاح .",
        'unban_not_banned': "- العضو غير محظور .",
    },
    'en': {
        'welcome': "👋🏻┇Welcome dear user to the bot for downloading from social media.\n\n"
                   "- You can download videos and audio in high quality.\n"
                   "- Help section platforms: ( YouTube, Instagram, Facebook, Twitter/X, TikTok, Pinterest, Snapchat ).",
        'banned': "You are banned from using this bot.",
        'subscribe_first': "You must subscribe to the channel, then send /start\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯",
        'searching': "- Searching...",
        'downloading': "Downloading...",
        'error_general': "An error occurred.",
        'error_link': "An error occurred, please make sure the link is correct.",
        'how_to_use_button': "⦗ How to use ⦘",
        'change_lang_button': "⦗ Language ⦘",
        'how_to_use_text': "Welcome to the help section. You can download by sending a direct link:\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ YouTube ﹞\n"
                           " - Send a YouTube video/music link.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ Instagram ﹞\n"
                           " - Send Reels/Stories link.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ Facebook ﹞\n"
                           " - Send the Facebook video link.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ Pinterest ﹞\n"
                           " - Send the Pinterest video link.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ Twitter/X ﹞\n"
                           " - Send the tweet link.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ TikTok ﹞\n"
                           " - Send the TikTok link.\n"
                           "┉┉┉┉┉┉┉┉┉┉┉\n"
                           "﹝ Snapchat ﹞\n"
                           " - Works only if the Snapchat link is public/openable in a browser (e.g., Spotlight/public share).\n"
                           " - Just send the Snapchat link.\n",
        'back_button': "⦗ Back ⦘",
        'choose_lang': "Choose your language:",
        'lang_changed': "Language changed successfully.",
        'admin_panel_title': "- Welcome, main developer.\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯\n- Choose an action:",
        'admin_panel_back': "- Welcome back, main developer.\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯\n- Control using buttons below.",
        'admin_broadcast': "⦗ Broadcast ⦘",
        'send_broadcast': "Send me the broadcast message.",
        'admin_ban': "⦗ Ban User ⦘",
        'send_id': "Send me the ID.",
        'admin_unban': "⦗ Unban User ⦘",
        'admin_stats': "⦗ Bot Statistics ⦘",
        'stats_title': "• Bot Statistics\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯\n",
        'stats_users': "• **Total Users:**",
        'stats_new': "• **New Users (24h):**",
        'stats_active': "• **Active Users (7d):**",
        'stats_banned': "• **Banned Users:**",
        'wait': "- Please wait...",
        'update_button': "⦗ Refresh ⦘",
        'ban_success': "- User has been banned successfully.",
        'ban_already': "- This user is already banned.",
        'ban_invalid_id': "- Please send a valid user ID.",
        'unban_success': "- User has been unbanned successfully.",
        'unban_not_banned': "- This user is not banned.",
    }
}

def get_lang(user_id):
    return db.get(f"user_lang_{user_id}") or 'ar'

def clear_user_state(user_id):
    if user_id in user_states:
        del user_states[user_id]

def build_admin_keyboard(lang):
    key = InlineKeyboardMarkup()
    l = LANGUAGES[lang]
    # ✅ فقط المطلوب: إذاعة + حظر/إلغاء + إحصائيات
    key.add(InlineKeyboardButton(l['admin_broadcast'], callback_data="admin_broadcast"))
    key.add(
        InlineKeyboardButton(l['admin_ban'], callback_data="admin_ban"),
        InlineKeyboardButton(l['admin_unban'], callback_data="admin_unban")
    )
    key.add(InlineKeyboardButton(l['admin_stats'], callback_data="admin_stats"))
    return key

def check_subscription(user_id, channels):
    # ✅ لم يعد مستخدماً بعد إلغاء الاشتراك الإجباري، لكنه موجود بدون تأثير على التحميل
    if not channels:
        return True, None, None
    for channel_id in channels:
        try:
            member = bot.get_chat_member(chat_id=channel_id, user_id=user_id)
            if member.status not in ['creator', 'administrator', 'member']:
                chat_info = bot.get_chat(channel_id)
                invite_link = chat_info.invite_link or bot.export_chat_invite_link(channel_id)
                return False, chat_info.title, invite_link
        except Exception as e:
            print(f"Error checking subscription for channel {channel_id}: {e}")
            return False, f"Channel ({channel_id})", None
    return True, None, None

@bot.message_handler(commands=['start'])
def start_command(message):
    user_id = message.from_user.id
    lang = get_lang(user_id)
    l = LANGUAGES[lang]
    clear_user_state(user_id)

    if user_id in (db.get("banned_users") or []):
        bot.send_message(user_id, l['banned'])
        return

    # ✅ تم حذف الاشتراك الإجباري وزر القناة بالكامل

    all_users = db.get("user_ids") or []
    if user_id not in all_users:
        all_users.append(user_id)
        db.set("user_ids", all_users)
        db.set(f"user_info_{user_id}", {'id': user_id, 'join_date': time.time(), 'last_active': time.time()})
    else:
        user_data = db.get(f"user_info_{user_id}")
        if user_data:
            user_data['last_active'] = time.time()
            db.set(f"user_info_{user_id}", user_data)

    start_keyboard = InlineKeyboardMarkup(row_width=1)
    start_keyboard.add(
        InlineKeyboardButton(l['how_to_use_button'], callback_data="show_help"),
        InlineKeyboardButton(l['change_lang_button'], callback_data="change_lang")
    )
    bot.send_message(message.chat.id, l['welcome'], reply_markup=start_keyboard)

    if user_id in ADMIN_IDS:
        admin_keyboard = build_admin_keyboard(lang)
        bot.send_message(user_id, l['admin_panel_title'], reply_markup=admin_keyboard)

@bot.callback_query_handler(func=lambda call: True)
def callback_query_handler(call):
    user_id = call.from_user.id
    lang = get_lang(user_id)
    l = LANGUAGES[lang]
    data = call.data
    message = call.message

    if user_id in (db.get("banned_users") or []):
        bot.answer_callback_query(call.id, l['banned'], show_alert=True)
        return

    if data.startswith("admin_"):
        if user_id not in ADMIN_IDS:
            bot.answer_callback_query(call.id, "انجب ." if lang == 'ar' else "Not for you.", show_alert=True)
            return
        handle_admin_callbacks(call)
        return

    if data == "show_help":
        keyboard = InlineKeyboardMarkup().add(InlineKeyboardButton(l['back_button'], callback_data="back_to_start"))
        bot.edit_message_text(l['how_to_use_text'], message.chat.id, message.message_id, reply_markup=keyboard)

    elif data == "change_lang":
        keyboard = InlineKeyboardMarkup(row_width=1)
        keyboard.add(
            InlineKeyboardButton("العربية 🇮🇶", callback_data="set_lang_ar"),
            InlineKeyboardButton("English 🇬🇧", callback_data="set_lang_en")
        )
        keyboard.add(InlineKeyboardButton(l['back_button'], callback_data="back_to_start"))
        bot.edit_message_text(l['choose_lang'], message.chat.id, message.message_id, reply_markup=keyboard)

    elif data.startswith("set_lang_"):
        new_lang = data.split('_')[-1]
        db.set(f"user_lang_{user_id}", new_lang)
        l_new = LANGUAGES[new_lang]
        bot.answer_callback_query(call.id, l_new['lang_changed'])
        start_keyboard = InlineKeyboardMarkup(row_width=1)
        start_keyboard.add(
            InlineKeyboardButton(l_new['how_to_use_button'], callback_data="show_help"),
            InlineKeyboardButton(l_new['change_lang_button'], callback_data="change_lang")
        )
        bot.edit_message_text(l_new['welcome'], message.chat.id, message.message_id, reply_markup=start_keyboard)

    elif data == "back_to_start":
        start_keyboard = InlineKeyboardMarkup(row_width=1)
        start_keyboard.add(
            InlineKeyboardButton(l['how_to_use_button'], callback_data="show_help"),
            InlineKeyboardButton(l['change_lang_button'], callback_data="change_lang")
        )
        bot.edit_message_text(l['welcome'], message.chat.id, message.message_id, reply_markup=start_keyboard)

def handle_admin_callbacks(call):
    data = call.data
    message = call.message
    user_id = call.from_user.id
    lang = get_lang(user_id)
    l = LANGUAGES[lang]
    back_button = InlineKeyboardButton(l['back_button'], callback_data="admin_back")
    keyboard = InlineKeyboardMarkup().add(back_button)

    if data == "admin_broadcast":
        bot.edit_message_text(l['send_broadcast'], message.chat.id, message.message_id, reply_markup=keyboard)
        user_states[user_id] = {'state': 'broadcast'}

    elif data == "admin_ban":
        bot.edit_message_text(l['send_id'], message.chat.id, message.message_id, reply_markup=keyboard)
        user_states[user_id] = {'state': 'ban'}

    elif data == "admin_unban":
        bot.edit_message_text(l['send_id'], message.chat.id, message.message_id, reply_markup=keyboard)
        user_states[user_id] = {'state': 'unban'}

    elif data == "admin_stats":
        now = time.time()
        all_users = db.get("user_ids") or []
        banned_users = db.get("banned_users") or []
        new_users_24h = sum(1 for uid in all_users if now - (db.get(f"user_info_{uid}") or {}).get('join_date', 0) <= 86400)
        active_users_7d = sum(1 for uid in all_users if now - (db.get(f"user_info_{uid}") or {}).get('last_active', 0) <= 604800)
        stats_text = (
            f"{l['stats_title']}"
            f"{l['stats_users']} {len(all_users)}\n"
            f"{l['stats_new']} {new_users_24h}\n"
            f"{l['stats_active']} {active_users_7d}\n"
            f"{l['stats_banned']} {len(banned_users)}\n"
        )
        bot.edit_message_text(stats_text, message.chat.id, message.message_id, parse_mode="Markdown", reply_markup=keyboard)

    elif data == "admin_back":
        clear_user_state(user_id)
        admin_keyboard = build_admin_keyboard(lang)
        bot.edit_message_text(l['admin_panel_back'], message.chat.id, message.message_id, reply_markup=admin_keyboard)

@bot.message_handler(func=lambda message: True, content_types=['text', 'photo', 'video', 'document', 'audio', 'sticker', 'voice'])
def handle_all_messages(message):
    user_id = message.from_user.id
    if user_id in user_states:
        state_info = user_states[user_id]
        state = state_info['state']
        clear_user_state(user_id)
        if state == 'broadcast':
            broadcast_message_handler(message)
        elif state == 'ban':
            ban_user_handler(message)
        elif state == 'unban':
            unban_user_handler(message)
        return

    if message.text and (message.text.startswith('http://') or message.text.startswith('https://')):
        handle_link(message)

def handle_link(message):
    user_id = message.from_user.id
    lang = get_lang(user_id)
    l = LANGUAGES[lang]
    if user_id in (db.get("banned_users") or []):
        return

    # ✅ تم إلغاء فحص الاشتراك الإجباري هنا أيضاً (بدون تأثير على التحميل)

    user_data = db.get(f"user_info_{user_id}")
    if user_data:
        user_data['last_active'] = time.time()
        db.set(f"user_info_{user_id}", user_data)

    url = message.text.strip()
    processing_msg = bot.reply_to(message, l['searching'])

    try:
        session = requests.Session()
        session.headers.update({'user-agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36'})
        response = session.get("https://www.videofk.com/search", params={'url': url}, timeout=60)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        title_tag = soup.find('h2', class_='h2') or soup.find('div', class_='video-title')
        title = title_tag.text.strip() if title_tag else "media_download"
        safe_title = re.sub(r'[\\/*?:"<>|]', "", title)
        encrypted_links = [{"text": link.text.strip().lower(), "encrypted": link['href'].split('#url=')[1]}
                           for link in soup.find_all('a', href=re.compile(r'#url='))]
        if not encrypted_links:
            raise ValueError(l['error_general'])

        bot.edit_message_text(l['downloading'], chat_id=processing_msg.chat.id, message_id=processing_msg.message_id)

        best_video, best_audio_url, no_watermark_video_url = {'url': None, 'size': 0}, None, None
        for link in encrypted_links:
            try:
                resp = requests.get(
                    'https://downloader.twdown.online/load_url',
                    params={'url': link['encrypted']},
                    headers={'user-agent': 'Mozilla/5.0'},
                    timeout=60
                )
                if not (resp.ok and resp.text.strip().startswith('http')):
                    continue
                final_url = resp.text.strip()
                is_audio = any(keyword in link['text'] for keyword in ['mp3', 'm4a', 'aac', 'kbps'])
                if is_audio and not best_audio_url:
                    best_audio_url = final_url
                elif not is_audio:
                    if 'without water' in link['text']:
                        no_watermark_video_url = final_url
                        break
                    size = int(requests.head(final_url, allow_redirects=True, timeout=60).headers.get('Content-Length', 0))
                    if size > best_video['size']:
                        best_video['url'], best_video['size'] = final_url, size
            except Exception:
                continue

        final_video_to_send = no_watermark_video_url or best_video['url']
        sent_count = 0
        for media_type, media_url in [('video', final_video_to_send), ('audio', best_audio_url)]:
            if not media_url:
                continue
            try:
                media_content = requests.get(media_url, headers={"User-Agent": "Mozilla/5.0"}, timeout=60).content
                if len(media_content) > 49 * 1024 * 1024:
                    continue
                stream = io.BytesIO(media_content)
                if media_type == 'video':
                    bot.send_video(message.chat.id, stream, caption=safe_title)
                else:
                    bot.send_audio(message.chat.id, stream, title=safe_title)
                sent_count += 1
            except Exception as e:
                print(f"Failed to send {media_type}: {e}")

        if sent_count > 0:
            bot.delete_message(processing_msg.chat.id, processing_msg.message_id)
        else:
            bot.edit_message_text(l['error_general'], chat_id=processing_msg.chat.id, message_id=processing_msg.message_id)

    except Exception:
        bot.edit_message_text(l['error_link'], chat_id=processing_msg.chat.id, message_id=processing_msg.message_id)

def broadcast_message_handler(message):
    all_users = db.get("user_ids") or []
    sent_count, failed_count = 0, 0
    bot.reply_to(message, f"بدأت الإذاعة إلى {len(all_users)} مستخدم ...")
    for user_id in all_users:
        try:
            bot.copy_message(chat_id=user_id, from_chat_id=message.chat.id, message_id=message.message_id)
            sent_count += 1
            time.sleep(0.05)
        except Exception as e:
            print(f"Failed to send to {user_id}: {e}")
            failed_count += 1
    bot.send_message(
        message.chat.id,
        f"انتهت الإذاعة .\n⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯ ⎯    \n\n- أُرسلت إلى: {sent_count} مستخدم.\n- فشل الإرسال إلى: {failed_count} مستخدم."
    )

def ban_user_handler(message):
    lang = get_lang(message.from_user.id)
    l = LANGUAGES[lang]
    try:
        user_id = int(message.text)
        banned_list = db.get("banned_users") or []
        if user_id not in banned_list:
            banned_list.append(user_id)
            db.set("banned_users", banned_list)
            bot.reply_to(message, l['ban_success'])
        else:
            bot.reply_to(message, l['ban_already'])
    except ValueError:
        bot.reply_to(message, l['ban_invalid_id'])

def unban_user_handler(message):
    lang = get_lang(message.from_user.id)
    l = LANGUAGES[lang]
    try:
        user_id = int(message.text)
        banned_list = db.get("banned_users") or []
        if user_id in banned_list:
            banned_list.remove(user_id)
            db.set("banned_users", banned_list)
            bot.reply_to(message, l['unban_success'])
        else:
            bot.reply_to(message, l['unban_not_banned'])
    except ValueError:
        bot.reply_to(message, l['ban_invalid_id'])

if __name__ == '__main__':
    print("تم تشغيل البوت بنجاح .")
    bot.infinity_polling()
import time
import sys
import os
import random
import re
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "1"
import pygame
from colorama import init, Fore, Style
init(autoreset=True)

import json  # <-- 新增存档所需

PINK = Fore.MAGENTA
RED = Fore.RED
YELLOW = Fore.YELLOW
GREEN = Fore.GREEN
BLUE = Fore.CYAN
WHITE = Fore.WHITE

RESET = Style.RESET_ALL
pass_game = False

sensitive_words = ["冯智轩", "fzx", "FZX"]

# ---------- 存档相关 ----------
SAVE_FILE = "save.json"

def save_game(data):
    """写入存档到当前目录的 save.json（UTF-8）"""
    try:
        with open(SAVE_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"\n{BLUE}【系统】进度已成功保存！{RESET}\n")
    except Exception as e:
        print(f"保存进度失败：{e}")

def load_game():
    """读取存档，找不到返回 None"""
    try:
        if not os.path.exists(SAVE_FILE):
            return None
        with open(SAVE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        print("\n【系统】已读取上次存档！\n")
        return data
    except Exception as e:
        print(f"读取存档失败：{e}")
        return None

def safe_get(d, key, default=None):
    """从 dict 安全获取，非 dict 返回 default"""
    return d.get(key, default) if isinstance(d, dict) else default

# === 从 .txt 文件读取对话 ===
def load_conversations(file_name):
    path = os.path.join("paperwork", file_name)
    if not os.path.exists(path):
        print(f"未找到对话文件：{path}")
        return []

    with open(path, "r", encoding="utf-8") as f:
        content = f.read().strip()

    # 每段对话之间用空行分隔
    raw_blocks = [block.strip() for block in re.split(r'\r?\n\r?\n', content) if block.strip()]
    conversations = []

    for block in raw_blocks:
        lines = []
        for line in block.splitlines():
            if line.startswith("PLAYER:"):
                lines.append({"speaker": "PLAYER", "text": line[7:].strip()})
            elif line.startswith("hina:"):
                lines.append({"speaker": "hina", "text": line[5:].strip()})
            else:
                lines.append({
                    "speaker": "narration",
                    "text": line
                })

        conversations.append(lines)

    return conversations

# 打印函数
def typewriter(text, speed=0.08):
    for char in text:
        print(char, end='', flush=True)
        time.sleep(speed)
    input("\n")

def colorwork(text, color=Fore.WHITE, speed=0.08):
    for char in text:
        sys.stdout.write(color + char)
        sys.stdout.flush()
        time.sleep(speed)
    input("\n")
    print()

def shake_text(text, color=Fore.WHITE, speed=0.08, intensity=2, times=10):
    for _ in range(times):
        offset = " " * random.randint(0, intensity)
        sys.stdout.write(f"\r{offset}{color}{text}{Style.RESET_ALL}")
        sys.stdout.flush()
        time.sleep(speed)
    input("\n")
    print()

#获取名字
def get_player_name():
    while True:
        name = input("请输入你的名字：").strip()
        if not name:
            print("名字不能为空，请重新输入。")
            continue
        if any(word in name for word in sensitive_words):
            print("该名字不可使用，请重新输入。")
            continue
        if len(name) > 9:
            print("名字不能超过9个字符，请重新输入。")
            continue
        return name

# ========== 音频模块 ==========
# NOTE: pygame.mixer.init() 可能在某些无声环境或无音频硬件的服务器上出错，
# 如果运行时报错，可以注释掉下面两行或者捕获异常。
try:
    pygame.mixer.init()
except Exception:
    # 在无法初始化音频时，继续游戏但不播放声音
    print("警告：无法初始化音频，音效将被禁用。")

def play_bgm(file_name, volume=0.5, fade_ms=2000):
    """播放背景音乐"""
    try:
        bgm_path = os.path.join("music", file_name)
        if not os.path.exists(bgm_path):
            return
        pygame.mixer.music.load(bgm_path)
        pygame.mixer.music.play(-1, fade_ms=fade_ms)  # 无限循环播放
        pygame.mixer.music.set_volume(volume)
    except Exception:
        # 忽略音频播放错误
        pass

def stop_bgm(fadeout_time=2000):
    """淡出停止BGM"""
    try:
        pygame.mixer.music.fadeout(fadeout_time)
    except Exception:
        pass

def play_sound(file_name, volume=0.8):
    """播放短音效"""
    try:
        sound_path = os.path.join("music", file_name)
        if not os.path.exists(sound_path):
            return
        sound = pygame.mixer.Sound(sound_path)
        sound.set_volume(volume)
        sound.play()
    except Exception:
        pass

# 统一对白显示函数
def show_dialogue(dialog, player_name):
    effect = dialog.get("effect", "typewriter")
    text = dialog["text"].replace("PLAYER", player_name)  # 替换占位符
    if "bgm" in dialog:
        play_bgm(dialog["bgm"])
    if "sound" in dialog:
        play_sound(dialog["sound"])
    if effect == "typewriter":
        typewriter(text)
    elif effect == "color":
        colorwork(text, color=dialog.get("color", Fore.WHITE))
    elif effect == "shake":
        shake_text(text, color=dialog.get("color", Fore.WHITE))

# 游戏开始界面
def start_screen():
    os.system('cls' if os.name == 'nt' else 'clear')
    try:
        width = os.get_terminal_size().columns  # 获取当前控制台宽度
    except OSError:
        width = 80
    subtitle = "A Journey Beyond Earth"
    border = "=" * width
    print(border)
    print("█▀▄▀█ ▄▀█ █▀█ █▀".center(width))
    print("█ ▀ █ █▀█ █▀▄ ▄█".center(width))
    print(border)
    print(Fore.LIGHTWHITE_EX + subtitle.center(width))
    print()
    print("按下回车键开始游戏...")
    input("\n")

def paperwork_star(player_name):
    for dialog in dialogues:
        show_dialogue(dialog, player_name)

# 游戏对白数据化
dialogues = [
    {"text": "我站在拜科努尔航天中心的登船口，防护服的头盔夹在腋下，空气里混着金属与海盐的味道。","bgm": "game_star.mp3"},
    {"text": "公元6202年，地球已经没有“春天”这个词了，只有灰黄色的尘霾和此起彼伏的资源警报。"},
    {"text": "火星开拓局的广播用冷冰冰的女声重复着：“双人舱位，随机配对，禁止拒绝。”"},
    {"text": "我以为我会抽到一个大胡子老工程师，或者是个能扛得动基建物资的壮汉。"},
    {"text": "结果，闸门滑开，走出来的是个子比我矮一头的女孩。"},
    {"text": "她穿着同样款式的橙色防护服，却把内衬拉链故意拉到最下面一颗扣子，露出锁骨上一道浅浅的旧疤。"},
    {"text": "棕色长发在无重力通道里飘得像海藻，眼睛是那种看过太多告别仪式后剩下的冷调褐色。她抱着头盔，冲我抬了抬下巴。"},
    {"text": "【少女】你就是我的驾驶员？", "effect": "color", "color": PINK},
    {"text": "【PLAYER】我是导航兼生命保障。你呢？", "effect": "color", "color": YELLOW},
    {"text": "【少女】米多莉·希娜，火星地质调查，记住就行。", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】别拖我后腿，我可不想死在半路上。", "effect": "color", "color": PINK},
    {"text": "【PLAYER】我也不想。飞船编号F-47，十分钟后点火，你最好快点。", "effect": "color", "color": YELLOW},
    {"text": "她“啧”了一声，从我身边擦过，头发扫过我手腕，带着一点柑橘味的消毒水香。"},
    {"text": "我盯着她背影，那件防护服明显大了一号，身躯小得像随时能被火星风吹跑,可她的样子却像要把整片赤道风暴都踩在脚底。"},
    {"text": "进入飞船后舱门“咔哒”一声锁死，我刚把行李固定好，她就已经把靴子跷在主控台上，头盔随手扔在副驾驶座——也就是我的位置。"},
    {"text": "【PLAYER】喂，那是我的椅子。", "effect": "color", "color": YELLOW},
    {"text": "【米多莉·希娜】谁规定副驾驶就得坐右边？", "effect": "color", "color": PINK},
    {"text": "她连眼皮都没抬，指尖在触控屏上飞快滑动。"},
    {"text": "【米多莉·希娜】反正你只是个导航，坐后面也一样。", "effect": "color", "color": PINK},
    {"text": "【PLAYER】我还要管生命保障，离氧气阀近一点比较......", "effect": "color", "color": YELLOW},
    {"text": "【米多莉·希娜】啰嗦。", "effect": "color", "color": PINK},
    {"text": "她突然把头盔扔过来，我手忙脚乱接住。"},
    {"text": "【米多莉·希娜】拿着，别摔了我的幸运物。", "effect": "color", "color": PINK},
    {"text": "头盔内衬贴着一张褪色的Hello Kitty贴纸，角落写着潦草的日文：絶対死ぬな。"},
    {"text": "【PLAYER】哈哈哈哈你还信这个？", "effect": "color", "color": YELLOW},
    {"text": "她耳朵瞬间炸红，猛地抢回头盔。"},
    {"text": "【米多莉·希娜】笑什么笑！不许看！", "effect": "shake", "color": PINK},
    {"text": "【PLAYER】好好好，不看。", "effect": "color", "color": YELLOW},
    {"text": "我举手投降，把头盔递回去，故意用只有她能听见的声音补刀。"},
    {"text": "【PLAYER】原来怕死啊？", "effect": "color", "color": YELLOW},
    {"text": "【米多莉·希娜】才、没有！", "effect": "shake", "color": PINK},
    {"text": "她把头盔扣在头上，面罩“啪”地放下。"},
    {"text": "【米多莉·希娜】我只是……只是怕无聊死了而已！", "effect": "color", "color": PINK},
    {"text": "这时飞船压力警报灯转绿，地面塔台用英语倒数："},
    {"text": "TEN..."},
    {"text": "NINE..."},
    {"text": "EIGHT..."},
    {"text": "倒数还没结束，希娜突然侧过头。"},
    {"text": "【米多莉·希娜】喂，大叔。飞...", "effect": "color", "color": PINK},
    {"text": "【PLAYER】我二十四。", "effect": "color", "color": YELLOW},
    {"text": "被我打断后她嘴角翘了一下，算是笑了吗？"},
    {"text": "【米多莉·希娜】算了。", "effect": "color", "color": PINK},
    {"text": "发动机点火的震动瞬间淹没一切。我被按进座椅，视网膜显示器里地球迅速缩成一颗发光的玻璃弹珠。"},
    {"text": "她的侧脸在蓝色仪表光里像一把出鞘的短刀，锋利，又脆弱。"},
    {"text": "三十秒后，我们正式脱离近地轨道。"},
    {"text": "【AI】预计近光速航程两天，祝二位旅途愉快。", "effect": "color", "color": BLUE},
    {"text": "【米多莉·希娜】谁跟你‘二位’了，我一个人也能飞到火星。", "effect": "color", "color": PINK},
    {"text": "她把安全带勒得更紧，指节发白,但依旧嘴硬。"},
    {"text": "我没接话，只是伸手调高了舱内氧气浓度。窗外，地球的轮廓已经看不见了，只剩下一片绝对的黑色，和她映在玻璃上的倒影。"},
    {"text": "起飞后第17小时。"},
    {"text": "飞船稳定在0.99997c的阿尔库别瑞巡航段，"},
    {"text": "外部时间被压缩成一张薄纸，火星像被谁猛地推过来的血橙，7小时后就会把整个舷窗塞满。"},
    {"text": "米多莉·希娜把主驾驶座倒转180度，双腿翘上仪表盘，脚尖晃啊晃，怀里抱着她那包“地质样本。”"},
    {"text": "其实全是鲣鱼饭团、草莓牛奶铝包，还有一罐偷偷藏的梅子酒。"},
    {"text": "她已经脱了防护服，只剩一件松垮到能当裙子的旧NASA T恤，领口歪到一边，锁骨上的旧疤在冷白灯光下像一道倔强的闪电。"},
    {"text": "【米多莉·希娜】喂。", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】你到底有没有名字？总不能让我在火星立碑写“与某某一同阵亡”吧。", "effect": "color", "color": PINK},
    {"text": "【PLAYER】PLAYER", "effect": "color", "color": YELLOW},
    {"text": "【米多莉·希娜】PLAYER", "effect": "color", "color": PINK},
    {"text": "她把拼写在舌尖上滚了一圈。"},
    {"text": "【米多莉·希娜】哈哈哈什么破名字，像游戏里三流反派。", "effect": "shake", "color": PINK},
    {"text": "【PLAYER】总比你强。", "effect": "color", "color": YELLOW},
    {"text": "【PLAYER】米多莉，听起来像便利店新品饮料。", "effect": "color", "color": YELLOW},
    {"text": "她差点把草莓牛奶喷出来"},
    {"text": "【米多莉·希娜】哈？！这是高贵和风命名！你这种三流反派懂什么！", "effect": "shake", "color": PINK},
    {"text": "第20小时。减速备降阶段。"},
    {"text": "我们在驾驶舱观察着火星。看着火星北极冠的季节融化纹路，清晰得像有人拿刀划出的伤口。"},
    {"text": "希娜突然把额头抵在舷窗上，呼出的雾气一圈圈晕开。"},
    {"text": "【米多莉·希娜】喂，PLAYER", "effect": "color", "color": PINK},
    {"text": "【PLAYER】干嘛", "effect": "color", "color": YELLOW},
    {"text": "【米多莉·希娜】你怕死吗？", "effect": "color", "color": PINK},
    {"text": "【PLAYER】无所谓，你呢？", "effect": "color", "color": YELLOW},
    {"text": "她没立刻回答，长发漂在我们中间，像一团不肯落地的棕色云。"},
    {"text": "【PLAYER】那就别死。系好安全带，减速G值会...", "effect": "color", "color": YELLOW},
    {"text": "我正要伸手把她往回拽"},
    {"text": "轰！", "effect": "shake", "color": RED,"sound": "boom.mp3"},
    {"text": "飞船像被看不见的巨锤侧面砸中，剧烈一震。"},
    {"text": "【AI】警告！未知高能粒子流击穿主引擎磁约束！", "effect": "shake", "color": RED,"sound": "danger.mp3"},
    {"text": "【AI】聚变炉失控！", "effect": "shake", "color": RED,"sound": "danger.mp3"},
    {"text": "【AI】推力向量偏移！30秒后姿态失控！！", "effect": "shake", "color": RED,"sound": "danger.mp3"},
    {"text": "我一把抓住她手腕,"},
    {"text": "她的瞳孔缩成针尖。"},
    {"text": "【PLAYER】座椅！现在！", "effect": "color", "color": YELLOW},
    {"text": "她却反手扣住我，指甲掐进我皮肉."},
    {"text": "【米多莉·希娜】来不及！减速窗口30秒！", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】必须手动翻转90度，用化学火箭强行制动！否则直接烧成灰！", "effect": "color", "color": PINK},
    {"text": "她踹开地板磁锁，像离弦的箭冲向后舱。"},
    {"text": "我紧跟其后，心脏在耳膜里打鼓。"},
    {"text": "后舱操作台前，她手指快到残影，屏幕跳出刺眼的红字:"},
    {"text": "【备用化学火箭点火延迟：4.7秒】！", "effect": "shake", "color": RED},
    {"text": "【米多莉·希娜】该死！", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】你去左舷手动阀门！我右舷！4秒内同时拉到底！听懂没！", "effect": "color", "color": PINK},
    {"text": "她话音未落，我已经冲向左舷，磁力靴踩得甲板咚咚响。"},
    {"text": "【米多莉·希娜】三！", "effect": "color", "color": PINK},
    {"text": "她声音在身后炸开，像最后通牒。"},
    {"text": "【米多莉·希娜】二！", "effect": "color", "color": PINK},
    {"text": "我抓住冰冷的红色手柄，掌心全是汗。"},
    {"text": "【米多莉·希娜】一！", "effect": "shake", "color": PINK},
    {"text": "我们同时猛拉。"},
    {"text": "化学火箭轰然喷射，飞船像被巨人在屁股上踹了一脚，疯狂翻滚。"},
    {"text": "过载瞬间飙到11G，我眼前发黑，只听见希娜一声短促的尖叫。"},
    {"text": "等视野恢复，飞船勉强对准火星大气层，但入射角偏了7度。"},
    {"text": "【AI】外壳温度5300K！45秒后解体！", "effect": "shake", "color": RED},
    {"text": "希娜踉跄冲回主控台，左手按在操纵杆上，右手却死死捂住右腹。"},
    {"text": "鲜血从指缝涌出，漂成一串猩红的珠子。"},
    {"text": "【PLAYER】你！", "effect": "shake", "color": YELLOW},
    {"text": "【米多莉·希娜】闭嘴！", "effect": "shake", "color": PINK},
    {"text": "【米多莉·希娜】我来修正！你去开紧急迫降程序！", "effect": "shake", "color": PINK},
    {"text": "【米多莉·希娜】埃利西姆平原！坐标37.2N, 148.8E！", "effect": "shake", "color": PINK},
    {"text": "我扑向副驾驶屏，手指快到抽筋。"},
    {"text": "她用仅剩的力气把操纵杆推到底。"},
    {"text": "飞船一头扎进火星大气层，橘红色的等离子体吞没舷窗，像掉进熔化的铜汁。"},
    {"text": "剧烈颠簸中，我看见她被安全带勒得几乎折断。"},
    {"text": "血珠在失重里四散飞溅，她却死死盯着高度表，声音虚弱却固执："},
    {"text": "【米多莉·希娜】高度……8000……5000……开伞……现在！", "effect": "color", "color": PINK},
    {"text": "我猛拍开伞键。"},
    {"text": "巨响。三具巨型减速伞炸开，飞船像被无形的手狠狠拽住，紧接着着陆引擎逆喷，火柱把沙尘掀上百米。"},
    {"text": "最后一声震耳欲聋的闷响，我们砸进埃利西姆平原正中央，扬起遮天蔽日的红尘。"},
    {"text": "舱内灯全灭，只剩应急红光。"},
    {"text": "我解开安全带，扑向她。"},
    {"text": "希娜瘫在座椅里，右腹被撕裂的金属片捅穿，血在火星1/3重力下缓缓涌出，把那件NASA T恤染成更深的红。"},
    {"text": "她脸色白得像极冠的冰，长发黏在嘴角，沾着血迹。"},
    {"text": "我蹲坐在她面前，手抖得几乎解不开急救包。"},
    {"text": "她却抬起没血的那只手，指节发白地揪住我衣领，声音轻得像火星的风。"},
    {"text": "【米多莉·希娜】喂……PLAYER……", "effect": "color", "color": PINK},
    {"text": "【PLAYER】别说话！我给你止血！", "effect": "shake", "color": YELLOW},
    {"text": "【米多莉·希娜】听好了……", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】前30天……你得一个人……把栖息舱充气……", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】把太阳能板展开……把水循环修好……把温室种上……我的那包种子……", "effect": "color", "color": PINK},
    {"text": "【PLAYER】闭嘴！", "effect": "shake", "color": YELLOW},
    {"text": "【PLAYER】你不会有事的！", "effect": "shake", "color": YELLOW},
    {"text": "她摇头，眼皮在往下掉，声音越来越小。"},
    {"text": "【米多莉·希娜】笨……蛋……这是……命令……", "effect": "color", "color": PINK},
    {"text": "【PLAYER】希娜！", "effect": "shake", "color": YELLOW},
    {"text": "【米多莉·希娜】还有……", "effect": "color", "color": PINK},
    {"text": "她用尽最后力气，把额头抵在我手背上。"},
    {"text": "【米多莉·希娜】别……别把我埋了……我想……看地球升起来……从火星的地平线……", "effect": "color", "color": PINK},
    {"text": "她手从我衣领滑落，漂浮在半空，像一朵被风吹散的棕色蒲公英。"},
    {"text": "舱外，火星的风开始呼啸，卷着铁锈色的沙尘拍打舷窗。"},
    {"text": "【AI】飞船主能源已启动，祝您生存愉快。", "effect": "color", "color": BLUE},
    {"text": "我小心翼翼地把希娜抱进医疗仓，像抱着一袋随时会碎掉的玻璃"},
    {"text": "【AI】医疗仓电力剩余时长29天23小时47分。", "effect": "color", "color": BLUE},
    {"text": "她的血已经渗过止血凝胶，在医疗仓内拖出一道暗红的尾巴。"},
    {"text": "医务舱显示生命体征从31%掉到29%，又弹到30%，像故意逗我玩。"},
    {"text": "【PLAYER】坚持住！", "effect": "color", "color": YELLOW},
    {"text": "我咬着牙，把医疗仓拖过扭曲的过道。"},
    {"text": "【PLAYER】你敢死，我就把你那包梅子酒全倒进再循环水箱，让你喝一辈子酒味尿。", "effect": "color", "color": YELLOW},
    {"text": "她没力气骂我，只从氧气面罩里看到嘴角微微抽动。"},
    {"text": "栖息舱的自动充气程序卡在87%，阀门被沙尘咬死。"},
    {"text": "我把希娜暂时塞进逃生舱的角落，用恒温毯裹成粽子，自己抡起液压钳，试图砸开阀门。"},
    {"text": "哐！哐！哐！", "effect": "shake", "color": RED},
    {"text": "白色折叠材料终于“嘭”地鼓起来。"},
    {"text": "气压归位那一刻，我腿一软，直接跪在地上。"},
    {"text": "但没时间喘气了。"},
    {"text": "【AI】舱外辐射指数185%，建议立即转移核心基建模块。", "effect": "color", "color": BLUE},
    {"text": "我抬头，透过破损舷窗看见不远处掉落的那三箱“核心基建模块”——总重九吨。"},
    {"text": "原本要靠机械臂卸货，现在机械臂断成两截，像死掉的螳螂。"},
    {"text": "只能我自己用宇航服的外骨骼搬。"},
    {"text": "我把安全绳拴好，打开气闸门。火星的风像刀子，瞬间灌进来，温度计跳到-67℃。我踩进红沙，第一步就陷到小腿。"},
    {"text": "【PLAYER】希娜，数着。", "effect": "color","color": YELLOW},
    {"text": "【PLAYER】每搬一箱，你……就越快好起来。", "effect": "color", "color": YELLOW},
    {"text": "第一箱，太阳能板阵列，3.2吨。"},
    {"text": "第二箱，水循环与电解模块，2.9吨。"},
    {"text": "风更大了，沙子打在头盔上噼啪响，能见度不到五米。"},
    {"text": "返程走到栖息舱门口时，我脚下一绊，整个人扑倒，希娜在的医疗舱被撞出去一米远，氧气管脱落，警报尖叫。"},
    {"text": "我爬过去，手指抖得几乎插不回接口。插上的瞬间，她猛地咳出一口血，喷在面罩内侧，红得刺眼。"},
    {"text": "【PLAYER】再坚持一下……就一下……", "effect": "color", "color": YELLOW},
    {"text": "第三箱，温室与种子舱，2.7吨。"},
    {"text": "这是最后一箱，也是希娜最宝贝的“私货”——她用全部地质样本额度换来的日本青梗菜、四季豆、还有一小袋樱花种子。"},
    {"text": "当然，还有些调味料和日用品。白砂糖、辣椒粉和肥皂什么的。"},
    {"text": "我回到栖息舱时，整个人已经爬行状态，膝盖以下没知觉，双手血肉模糊。"},
    {"text": "门终于关上，气闸加压，温度回升。我把三箱模块按顺序插进接口。"},
    {"text": "【AI】核心基建模块对接完成。自动展开程序启动。预计完成时间：4小时37分。", "effect": "color", "color": BLUE},
    {"text": "我瘫坐在地上，打开了医疗仓的操作面板，自动缝合机启动，纳米线钻进她伤口，像一群银色蚂蚁。"},
    {"text": "血浆第三袋吊完，止痛贴第四片贴上。"},
    {"text": "【生命体征：46%】", "effect": "color", "color": GREEN},
    {"text": "随后我便倒在地上昏睡了过去。"},
    {"text": "不知过了多久，我醒了过来。"},
    {"text": "睁开双眼，埃利西姆平原的地平线还是一条冷硬的铁锈色刀锋。"},
    {"text": "太阳像被谁用钝刀硬生生割出来的一块烧红的铁，悬在东边，迟迟不肯升起。"},
    {"text": "我手里攥着地质铲，铲刃上还冻着霜，闪着幽蓝的冷光。"},
    {"text": "希娜在医务舱里。"},
    {"text": "她正躺着，氧气面罩蒙了一层雾，睫毛在医疗灯里投下细碎的阴影。"},
    {"text": "【生命体征：50%】", "effect": "color", "color": GREEN},
    {"text": "【PLAYER】昨天搬完电池板时是46%,好转的还蛮快的嘛。", "effect": "color", "color": YELLOW},
    {"text": "【PLAYER】飞船的物资还够我们撑五天。", "effect": "color", "color": YELLOW},
    {"text": "【PLAYER】五天。", "effect": "color", "color": YELLOW},
    {"text": "【PLAYER】五天后...", "effect": "color", "color": YELLOW},
    {"text": "【PLAYER】再睡一觉，希娜。我一个人应该也可以把任务搞定。", "effect": "color", "color": YELLOW},
]

# 取水反馈
water_responses = [
    "管道里传来轻微的水声。",
    "你拧紧过滤器，清澈的水慢慢汇入容器。",
    "取水过程异常顺利，今日运气不错。",
    "风沙刮过，你依然耐心地回收每一滴水。",
    "设备轻微震动，水流声令人安心。",
    "过滤网闪着蓝光，水珠像珍珠一样滚落。",
    "冷凝器滴答作响，你数着第37滴、第38滴……",
    "水箱水位上升了0.3升，今天够你和她喝两杯。",
    "你把容器举高，让最后一滴水滑进。",
    "蒸馏器嗡鸣，水汽在玻璃壁凝成细雾。",
    "晨露凝在金属板上，你用仪器轻轻一刮，滑进收集槽。",
    "渗水管发出低沉的咕噜声，像火星在打嗝。",
    "你站在冷凝器旁，只听到水滴落下的清脆回响。",
    "过滤器里残留的杂质被冲出，水流瞬间变得晶莹。",
    "水面浮起一层薄薄的冰晶，你用仪器划开，露出下面透亮的水。",
    "回收管壁结霜，你用体温焐热，冰水顺着管壁汩汩而下。",
    "露水在太阳能板边缘排成一串银线，你倾斜板面，全部收进。",
    "设备屏幕跳出“纯度99.7%”，你长舒一口气。",
    "水“咕咚”一声装满，重量压在手腕，真实得让人安心。",
    "最后一滴水悬在管口，你轻轻一弹，它落进容器，溅起细小涟漪。"
]

# 种植反馈
plant_responses = [
    "植物的叶片微微颤动，似乎在回应你的努力。",
    "你轻轻拨开土壤，嫩芽探出了头。",
    "温度稳定，作物的状态比昨天更好。",
    "阳光透过防护罩洒下，叶片泛着微光。",
    "种植舱内弥漫着泥土的气息。",
    "小松菜的根须缠住了营养块，贪婪地吸水。",
    "你给四季豆搭了新支架，它立刻往上爬了一厘米。",
    "温室灯自动调到2700K，叶子颜色更绿了。",
    "种植日志：今日光照时长 11 小时 47 分，创纪录。",
    "你轻轻抚过叶片，它像猫一样蹭了蹭你的指尖。"
]

# 维修反馈
repair_responses = [
    "你调节了维生装置的供能参数，系统嗡鸣平稳。",
    "几根线路重新连接，数据流重新畅通。",
    "修复成功，控制面板亮起蓝光。",
    "你的双手被油污染黑，但系统运行更加稳定。",
    "你听到机器的低鸣，希娜的呼吸似乎平稳了些。",
    "我用牙咬断多余的线头，血腥味混着机油，火星的味道。",
    "我把断裂的氧气管焊回原位，火星风在舱外呼啸，像在嘲笑我一个人修。",
    "水泵重新启动，滴水声像心跳……我数到第127下，才敢相信它不会停。",
    "我把烧毁的保险丝换掉，灯亮了。",
    "聚变瓶的约束磁场偏移了0.3%，我调了整整一夜，舱里只有我的呼吸声。"
]

# 聊天反馈
talk_responses = [
    "希娜，今天外面的风沙小了一点，我觉得这是个好兆头。",
    "你知道吗？我又修好了一个氧气管路……虽然只是一点点进步，但我相信你会醒来的。",
    "你的手还是那么冰，但我能感受到微弱的脉搏。你在努力，对吗？",
    "这里太安静了，除了我的呼吸声……我几乎忘了声音是什么样的感觉。",
    "你放心，我会坚持的。哪怕只剩最后一点体力，我也不会放弃你。",
    "我修好了氧气管路，你醒了估计会大吃一惊。",
    "我把今天收的0.8升水全倒进医疗仓里了，喝完它，别让我白攒。",
    "今天我给小松菜搭了新支架，它往上爬了1.3厘米。",
    "今天我修好了水循环机，滴水声像心跳。",
    "今天我把工具箱整理了三次，螺丝刀少了一把，找了两个小时。"
]

recipes = {
    "四季豆饼": {
        "require": {"四季豆": 1, "小麦": 1},
        "display": "四季豆饼(消耗：1份四季豆、1份小麦)"
    },
    "青菜面": {
        "require": {"青梗菜": 1, "小麦": 1},
        "display": "青菜面(消耗：1份青梗菜、1份小麦)"
    },
    "樱花发簪": {
        "require": {"小樱花": 1, "水": 5},
        "display": "樱花发簪(消耗：1份小樱花、5份水)"
    }
}

# 可赠送礼物
gift_affection = {
    "樱花发簪": "RANDOM"
}

# 礼物赠送后反馈
hina_gift_reactions = [
    "谢谢你，我会好好珍惜的。",
    "咦？真的是给我的吗？好开心！",
    "唔…我会更努力成为值得你送礼物的人！",
    "诶？突然送我这个…我有点害羞。",
    "我……真的很喜欢！",
    "谢谢，有你在火星真好。",
    "嘿嘿，我收下啦！以后也可以继续送哦？"
]

love_triggered = set()

love_topics = {
    25: "love25.txt",
    50: "love50.txt",
    75: "love75.txt",
    100: "love100.txt"
}

#每日选项显示函数
def print_panel(day, total_days, stamina, water, food, girl_health,plant_progress,is_planting,plant_needs_water,plant_dead):
    os.system('cls' if os.name == 'nt' else 'clear')
    remaining_days = total_days - day + 1
    print(f"{BLUE}====== 剩余 {remaining_days} 天 ======{RESET}\n")
    print(f"体力:{stamina} | 水:{water} | 食物:{food} | 生命体征:{girl_health:.1f}%")
    if plant_progress > 0:
        days_to_harvest = 3 - plant_progress
        print(f"作物生长中，还有 {days_to_harvest} 天收成")
    if is_planting and not plant_dead:
        if plant_needs_water:
            print("植物今天需要浇水。")
        else:
            print("植物今天状态良好，不需要浇水。")
    elif plant_dead:
        print("植物已经枯死，需要重新种植。")
    else:
        print("当前没有种植作物。")

    print("\n今日行动：")
    print("1. 取水（消耗2体力，获得3水份）")
    print("2. 种植/浇水（消耗2体力/1体力，3天一收成）")
    print("3. 维修设备（消耗3体力，提升3%生命体征）")
    print("4. 与希娜聊天（消耗1体力）")
    print("5. 结束当天（空余体力不会保留到第二天）\n")

# 游戏主函数
def main_game(player_name):
    # 默认数据
    total_days = 30
    day = 1
    stamina = 6
    water = 0
    food = 0
    plant_progress = 0
    girl_health = 50.0
    girl_max_health = 100.0
    is_planting = False
    plant_needs_water = False
    plant_dead = False
    global pass_game

    # 尝试读取主线存档（如果存在且模式为 main_game 则加载）
    try:
        saved = load_game()
        if saved and safe_get(saved, "mode") == "main_game":
            print("检测到主线存档，正在加载...")
            day = saved.get("day", day)
            stamina = saved.get("stamina", stamina)
            water = saved.get("water", water)
            food = saved.get("food", food)
            girl_health = saved.get("girl_health", girl_health)
            plant_progress = saved.get("plant_progress", plant_progress)
            is_planting = saved.get("is_planting", is_planting)
            plant_needs_water = saved.get("plant_needs_water", plant_needs_water)
            plant_dead = saved.get("plant_dead", plant_dead)
    except Exception as e:
        print(f"载入主线存档时发生异常：{e}")

    # 启动背景音乐
    play_bgm("main_game.mp3")
    print(f"{BLUE}【系统】生命支援系统启动中……{RESET}\n")
    time.sleep(1)
    print(f"{BLUE}【系统】任务目标：在30天内让米多莉·希娜的生命体征恢复到100%{RESET}\n")
    input("按回车开启系统。\n")

    while day <= total_days:
        print_panel(day, total_days, stamina, water, food, girl_health, plant_progress, is_planting, plant_needs_water, plant_dead)

        while stamina > 0:
            choice = input("选择行动：\n")
            print()

            # === 取水 ===
            if choice == "1" and stamina >= 2:
                stamina -= 2
                water += 3
                print(random.choice(water_responses))
                time.sleep(1)
                print("\n你收集到了3份水。")
                time.sleep(1)

            # === 种植 / 浇水 ===
            elif choice == "2":
                if (not is_planting or plant_dead) and stamina >= 2:  # 种植
                    stamina -= 2
                    plant_progress = 1
                    is_planting = True
                    plant_needs_water = True
                    plant_dead = False
                    print(random.choice(plant_responses))
                    time.sleep(1)
                    print("\n你种下了作物，它们开始生长。")
                    time.sleep(1)

                elif is_planting and not plant_dead:  # 浇水
                    if plant_needs_water:
                        if stamina >= 1:
                            stamina -= 1
                            plant_needs_water = False
                            print("你给植物浇了水，叶子显得更有精神了。")
                            time.sleep(1)
                            print()
                        else:
                            print("体力不足，无法浇水。")
                            time.sleep(1)
                            print()
                    else:
                        print("植物今天已经浇过水了。")
                        time.sleep(1)
                        print()
                elif plant_dead:
                    print("植物已经枯死，无法继续生长。")
                    time.sleep(1)
                    print()

                # 成熟检查
                if is_planting and not plant_dead and plant_progress >= 3:
                    food += 5
                    plant_progress = 0
                    is_planting = False
                    print("\n作物成熟，收获了5份食物！\n")
                    time.sleep(1)
                    print()

            # === 修缮设备 ===
            elif choice == "3" and stamina >= 3:
                stamina -= 3
                girl_health += 3
                print(random.choice(repair_responses))
                time.sleep(1)
                print("\n你修缮了生命维持装置，希娜回复的更快了。\n")
                time.sleep(1)

            # === 闲聊 ===
            elif choice == "4" and stamina >= 1:
                stamina -= 1
                print("你坐在医疗仓旁边，轻声说：")
                time.sleep(1)
                print()
                print(random.choice(talk_responses))
                time.sleep(1)
                print()

            # === 结束回合 ===
            elif choice == "5":
                print("你结束了今天的工作。\n")
                time.sleep(1)
                break
            else:
                print("体力不足或输入错误。\n")
                time.sleep(1)

            print(f"{BLUE}【系统】状态更新中请稍等（不要进行任何操作）...{RESET}\n")
            time.sleep(1)  # 缩短为 1s，加快测试体验
            print_panel(day, total_days, stamina, water, food, girl_health, plant_progress, is_planting, plant_needs_water, plant_dead)
            print(f"{BLUE}【系统】当前状态更新完成{RESET}\n")
            time.sleep(1)

        # === 日终结算 ===
        print(f"{BLUE}【系统】日终结算中……{RESET}\n")
        time.sleep(1)

        # 自动保存主线进度（每天结算后）
        try:
            save_game({
                "mode": "main_game",
                "player_name": player_name,
                "day": day,
                "stamina": stamina,
                "water": water,
                "food": food,
                "girl_health": girl_health,
                "plant_progress": plant_progress,
                "is_planting": is_planting,
                "plant_needs_water": plant_needs_water,
                "plant_dead": plant_dead
            })
        except Exception as e:
            print(f"自动存档失败：{e}")

        # 植物状态处理
        if is_planting and not plant_dead:
            if plant_needs_water:  # 未浇水 → 枯死
                plant_dead = True
                plant_progress = 0
                print("由于缺水，植物枯萎死亡了……")
                time.sleep(1)
                print()
            else:
                plant_progress += 1
                plant_needs_water = True  # 明天需要再浇水

        # 食物与水分消耗
        if day > 5:
            if water > 0:
                water -= 2
            else:
                girl_health -= 30
                print(f"{RED}【系统】缺水导致生命体征下降(生命体征下降30%）{RESET}\n")
                time.sleep(1)
            if food > 0:
                food -= 1
            else:
                girl_health -= 30
                print(f"{RED}【系统】饥饿让身体更加虚弱(生命体征下降30%）{RESET}\n")
                time.sleep(1)

        girl_health = min(girl_health, girl_max_health)

        # 提前结束判断
        if girl_health >= 100:
            break

        stamina = 6
        day += 1
        input("\n按回车进入下一天。\n")

    # === 结局判断 ===
    if girl_health >= 100:
        print(f"{BLUE}【系统】恭喜，{player_name}！你成功让米多莉·希娜恢复了生命体征！{RESET}\n")
        time.sleep(1)
        stop_bgm()
        pass_game = True
        time.sleep(1)
    else:
        print(f"{BLUE}【系统】任务失败……米多莉·希娜的生命体征未能完全恢复。{RESET}\n")
        time.sleep(1)
        print("\n在漫长的孤独与绝望中，你选择了结束自己的生命。\n")
        time.sleep(1)
        print(f"{RED}GAME OVER{RESET}\n")
        stop_bgm()
        time.sleep(5)

def paperwork_mid(player_name):
    for dialog in dialogues_mid:
        show_dialogue(dialog, player_name)

# ======== 游戏中期对白数据 ========
dialogues_mid = [
    {"text": "温室灯刚切到日出模式，2000K的暖黄光漫过培养床，第一批小松菜已经冒出两片子叶，嫩绿得像在挑衅这颗红色的星球。","bgm": "game_mid.mp3"},
    {"text": "我手里攥着0.3mm口径的喷壶，正给最中间那棵浇水。"},
    {"text": "突然，医务舱方向传来“咔哒”一声。"},
    {"text": "不是设备声，是锁扣被手动弹开的脆响。"},
    {"text": "向声音方向望去，我手一抖，喷壶直接掉进土里。"},
    {"text": "希娜扶着舱门，赤脚踩在金属地板上。"},
    {"text": "身上还穿着那件沾了干血的NASA T恤，下摆盖到大腿根，露出两条纤细白嫩的腿。"},
    {"text": "她头发乱得像被沙尘暴卷过，脸色白得透明，却站得笔直。"},
    {"text": "【AI】【希娜：生命体征：100%】 ", "effect": "color", "color": GREEN},
    {"text": "我张了张嘴，喉咙干得发疼。"},
    {"text": "快一个月没听见她说话，耳朵都快忘了她的声音。"},
    {"text": "【米多莉·希娜】……我的小松菜，你浇歪了。", "effect": "color", "color": PINK},
    {"text": "我低头，果然，水浇得有点多，把旁边那颗四季豆的子叶压弯了。"},
    {"text": "【PLAYER】我...", "effect": "color", "color": YELLOW},
    {"text": "【米多莉·希娜】笨蛋，这里要先浇根，再补叶，懂不懂？", "effect": "color", "color": PINK},
    {"text": "她一把夺过喷壶，蹲下去，动作熟练得像过去都是她亲自浇的。"},
    {"text": "我愣在原地，看着她侧脸。"},
    {"text": "【PLAYER】你饿不饿？输了好久营养液，我给你煮...", "effect": "color", "color": YELLOW},
    {"text": "【米多莉·希娜】煮什么。", "effect": "color", "color": PINK},
    {"text": "她头也不抬，手指已经掐下一片发黄的下叶扔进回收槽。"},
    {"text": "【米多莉·希娜】先把今天的分工定了。", "effect": "color", "color": PINK},
    {"text": "她站起身，把喷壶往我胸口一戳，力道大得我后退半步。"},
    {"text": "【米多莉·希娜】听好了，从今天起。", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】每天一个人外出收集水露并保养，一个人留舱负责粮食模块。", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】水要收集到不低于3.2升/天，粮食模块湿度波动不能超过±3%，光照周期误差不能超过5分钟。", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】晚上两人一起维护设备，氧气产量必须稳定在180升/小时以上，水循环效率不低于92%。", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】没异议就点头，废话少说。", "effect": "color", "color": PINK},
    {"text": "她一口气说完，顿了顿，声音低了半度。"},
    {"text": "【米多莉·希娜】还有……我的梅子酒呢？", "effect": "color", "color": PINK},
    {"text": "我从工具柜最上层掏出那罐被我藏起来的青梅酒，完好无损，连封口膜都没拆。"},
    {"text": "她一把抢过去，抱在怀里，像抱回一条命。"},
    {"text": "我点头"},
    {"text": "【PLAYER】没异议。", "effect": "color", "color": YELLOW},
    {"text": "她抬眼看我。"},
    {"text": "【米多莉·希娜】笨蛋，十个手指全是裂口，膝盖下的防护裤还有血痂。", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】今天我外出收水，你留舱。", "effect": "color", "color": PINK},
    {"text": "【米多莉·希娜】别把我的菜浇死。", "effect": "color", "color": PINK},
    {"text": "说完，她转身去穿防护服服，动作快得像怕我看见她腿在抖。"},
    {"text": "我看着她背影。"},
    {"text": "【PLAYER】希娜。", "effect": "color", "color": YELLOW},
    {"text": "【PLAYER】欢迎回来。", "effect": "color", "color": YELLOW},
    {"text": "她脚步一顿，没回头，只是拉上头盔拉链。"},
    {"text": "【米多莉·希娜】谁要你欢迎了。", "effect": "color", "color": PINK},
    {"text": "气闸门打开，她踩进红沙。"},
    {"text": "背影瘦得像一根随时会折的芦苇，却走得比从地球出发前任何一次模拟都稳。"},
    {"text": "我笑了一声，低头继续浇水。"},
    {"text": "水滴滴进土里，溅起细小的尘埃。"},
    {"text": "我轻声，对着土壤，也对着她看不见的背影说:"},
    {"text": "【PLAYER】慢慢来，希娜。", "effect": "color", "color": YELLOW},
    {"text": "希娜苏醒了,真正的火星生活正式开启..."},
    {"text": "【日常辅助系统开启】 ", "effect": "color", "color": BLUE},
]

# 对话文本库
talk_topics = {
    "1": "talk_earth.txt",
    "2": "talk_mars.txt",
    "3": "talk_recent.txt",
    "4": "talk_future.txt",
}
inventory = {}  # 背包系统
stamina_daily = 5  # 体力
affection = 0  # 女主好感度
day = 1  # 日期
planting_progress = {}  # 种植记录
planting = False

# 取水系统
def fetch_water():
    global stamina_daily
    stamina_daily -= 1
    inventory["水"] = inventory.get("水", 0) + 1
    print(random.choice(water_responses))
    time.sleep(1)
    print()
    print("你取了一桶水。当前水桶数量：", inventory["水"])
    time.sleep(1)

# 种植系统
def plant():
    """玩家进行种植"""
    global stamina_daily, planting, planting_progress

    if planting:
        print("已经有作物在生长中，等成熟后再种吧。")
        time.sleep(1)
        return

    print("可以种植的作物：")
    print("1. 四季豆\n2. 青梗菜\n3. 小樱花\n4. 小麦")
    choice = input("请选择要种的作物：")

    crops = {"1": "四季豆", "2": "青梗菜", "3": "小樱花", "4": "小麦"}
    if choice not in crops:
        print("无效选择。")
        time.sleep(1)
        return
    crop_name = crops[choice]
    stamina_daily -= 1
    planting_progress[crop_name] = [0]  # 代表这株植物从第0天开始生长
    planting = True
    print(f"你种下了 {crop_name}，它将在 2 天后成熟。")
    time.sleep(1)

# 植物生长自动更新
def update_plant_growth():
    global planting_progress, planting, inventory

    harvested = []

    # 遍历所有作物生长天数
    for crop_name in list(planting_progress.keys()):
        new_days = []
        for growth in planting_progress[crop_name]:
            growth += 1
            if growth >= 2:
                # 收成逻辑
                inventory[crop_name] = inventory.get(crop_name, 0) + 1
                harvested.append(crop_name)
            else:
                new_days.append(growth)
        planting_progress[crop_name] = new_days

    # 如果所有植物都成熟，则清空种植状态
    if not any(planting_progress.values()):
        planting = False

    # 输出提示
    if harvested:
        print("今天植物成熟了！")
        time.sleep(1)
        print(f"\n你收获了：{', '.join(harvested)}！已放入背包。")

# 对话系统
def talk(player_name):
    global affection, stamina_daily

    print("选择一个话题：")
    print("1. 地球")
    print("2. 火星")
    print("3. 最近")
    print("4. 神教")

    choice = input("请选择话题：")

    if choice not in talk_topics:
        print("无效选择。")
        time.sleep(1)
        return

    file_name = talk_topics[choice]
    conversations = load_conversations(file_name)
    if not conversations:
        print("该话题暂无内容。")
        time.sleep(1)
        return

    # 随机选取一段对话
    conversation = random.choice(conversations)

    for line in conversation:
        text = line["text"].replace("PLAYER", player_name)
        if line["speaker"] == "PLAYER":
            print(f"{YELLOW}【{player_name}】{text}{Style.RESET_ALL}")
            time.sleep(1)
        elif line["speaker"] == "hina":
            print(f"{PINK}【米多莉·希娜】{text}{Style.RESET_ALL}")
            time.sleep(1)
        input()

    # 增加好感度
    affection += 2
    stamina_daily -= 1
    if affection > 100:
        affection = 100

    # 不同好感度阶段输出不同提示
    if affection < 25:
        hint = "希娜微笑着回应你，但似乎还有点拘谨。"
    elif affection < 50:
        hint = "希娜似乎开始享受与你的交谈。"
    elif affection < 75:
        hint = "希娜的语气中带着温柔与信任。"
    elif affection < 100:
        hint = "希娜看着你时，眼神里闪着光。"
    else:
        hint = "希娜已经完全信任并依赖着你。"

    print(f"\n{hint}")
    time.sleep(1)
    print(f"（好感度 +2，当前好感度：{affection}/100）")
    time.sleep(1)

def open_inventory():
    global inventory, affection, stamina_daily

    while True:
        os.system('cls' if os.name == 'nt' else 'clear')
        print(f"{BLUE}==================================={RESET}")
        print(f"{BLUE}             背 包{RESET}")
        print(f"{BLUE}==================================={RESET}\n")

        if not inventory:
            print("背包是空的……\n")
            input("回车继续")
            return None

        print("当前背包内容：")
        for item, count in inventory.items():
            print(f"- {item} × {count}")

        print("\n你可以：")
        print("1. 制作物品")
        print("2. 赠送礼物")
        print("3. 返回游戏")

        choice = input("\n> 请输入选项： ")

        # 返回游戏
        if choice == "3":
            return None

        # 合成系统
        elif choice == "1":
            os.system('cls' if os.name == 'nt' else 'clear')
            print("当前背包内容：")
            for item, count in inventory.items():
                print(f"- {item} × {count}")
            print(f"{BLUE}========= 可合成物品 ========={RESET}")
            for i, product in enumerate(recipes.keys(), start=1):
                print(f"{i}. {recipes[product]['display']}")
            print("0. 取消")

            ch = input("\n> 选择编号： ")

            if ch == "0":
                continue

            try:
                product = list(recipes.keys())[int(ch) - 1]
            except:
                print("\n无效输入,请重新选择。")
                time.sleep(1)
                continue

            materials = recipes[product]["require"]

            # 检查材料是否足够
            can_make = True
            for mat, need in materials.items():
                if inventory.get(mat, 0) < need:
                    can_make = False

            if not can_make:
                print("\n材料不足，无法合成！")
                time.sleep(1)
                continue

            # 扣除材料
            for mat, need in materials.items():
                inventory[mat] -= need
                if inventory[mat] <= 0:
                    del inventory[mat]

            # 成品加入背包
            inventory[product] = inventory.get(product, 0) + 1
            stamina_daily -= 1
            print(f"\n制作完成！获得：{product}")
            time.sleep(1)
            continue

        # 送礼系统
        elif choice == "2":
            os.system('cls' if os.name == 'nt' else 'clear')
            # 过滤可送礼物（必须是 recipes 的成品）
            giftable_items = [item for item in inventory.keys() if item in gift_affection]

            if not giftable_items:
                print("背包里没有可赠送的物品。")
                input("回车继续")
                continue

            print(f"{BLUE}========= 可赠送礼物 ========={RESET}")
            for i, item in enumerate(giftable_items, start=1):
                print(f"{i}. {item} × {inventory[item]}")
            print("0. 取消")

            g = input("\n> 输入编号： ")

            if g == "0":
                continue

            try:
                gift = giftable_items[int(g) - 1]
            except:
                print("\n无效输入，请重新选择。")
                time.sleep(1)
                continue

            # 扣除背包
            inventory[gift] -= 1
            if inventory[gift] <= 0:
                del inventory[gift]

            # 增加好感度
            if gift_affection[gift] == "RANDOM":
                add = random.randint(5, 10)
            else:
                add = gift_affection[gift]

            affection += add

            hina_reply = random.choice(hina_gift_reactions)

            print(f"\n你送了【{gift}】给希娜(好感度 +{add})")
            print(f"【米多莉·希娜】{hina_reply}")
            input("回车继续")
            continue

        else:
            print("\n无效选择")
            time.sleep(1)
            continue

def check_love_event(player_name):
    global affection, love_triggered

    for threshold, file_name in love_topics.items():
        # 达到好感度并且没有触发过
        if affection >= threshold and threshold not in love_triggered:

            os.system('cls' if os.name == 'nt' else 'clear')
            print(f"【特殊事件触发】好感度达到 {threshold}！\n")
            time.sleep(1)

            conversations = load_conversations(file_name)
            if not conversations:
                print("（剧情文件未找到或内容为空）")
                love_triggered.add(threshold)
                return

            # 第一段对话
            conversation = conversations[0]

            # 打印方式
            for line in conversation:

                spk = line["speaker"]
                text = line["text"].replace("PLAYER", player_name)

                # 玩家
                if spk == "PLAYER":
                    full = f"【{player_name}】{text}"
                    for c in full:
                        sys.stdout.write(YELLOW + c + Style.RESET_ALL)
                        sys.stdout.flush()
                        time.sleep(0.1)
                    print()

                # 希娜
                elif spk == "hina":
                    full = f"【米多莉·希娜】{text}"
                    for c in full:
                        sys.stdout.write(PINK + c + Style.RESET_ALL)
                        sys.stdout.flush()
                        time.sleep(0.1)
                    print()

                # 旁白
                else:
                    for c in text:
                        sys.stdout.write(WHITE + c + Style.RESET_ALL)
                        sys.stdout.flush()
                        time.sleep(0.1)
                    print()

                time.sleep(1)
                input()

            love_triggered.add(threshold)  # 记录触发完成

            print("\n（按回车继续）")
            input()
            os.system('cls' if os.name == 'nt' else 'clear')
            return

# 长期游戏
def daily_life(player_name):
    global day, stamina_daily, affection, inventory, planting_progress, planting, love_triggered

    # 尝试读取长期生活存档（daily_life）
    try:
        saved = load_game()
        if saved and safe_get(saved, "mode") == "daily_life":
            print("检测到存档，正在加载...")
            day = saved.get("day", day)
            stamina_daily = saved.get("stamina_daily", stamina_daily)
            inventory = saved.get("inventory", inventory)
            affection = saved.get("affection", affection)
            planting_progress = saved.get("planting_progress", planting_progress)
            planting = saved.get("planting", planting)
            love_triggered = set(saved.get("love_triggered", list(love_triggered)))
    except Exception as e:
        print(f"加载存档时发生异常：{e}")

    play_bgm("daily_life.mp3")
    while True:
        os.system('cls' if os.name == 'nt' else 'clear')  # 清屏实现刷新效果
        print(f"{BLUE}====== 火星生活第 {day} 天 ======{RESET}\n")
        print(f"体力：{stamina_daily} / 5")
        print(f"希娜好感度：{affection}/100\n")
        print("1. 取水")
        print("2. 种植")
        print("3. 和希娜聊天")
        print("4. 背包/工作台")
        print("5. 探险（暂未开放）")
        print("6. 睡觉（睡到下一天）")
        choice = input("请选择行动：")

        if choice == "1":
            if stamina_daily < 1:
                print("体力不足，无法取水。")
                time.sleep(1)
            else:
                fetch_water()
        elif choice == "2":
            if stamina_daily < 1:
                print("体力不足，无法种植。")
                time.sleep(1)
            else:
                plant()
        elif choice == "3":
            if stamina_daily < 1:
                print("体力不足，希娜说好困了，想早点睡。")
                time.sleep(1)
            else:
                talk(player_name)
        elif choice == "4":
            open_inventory()
        elif choice == "5":
            print("探险系统尚未开放。")
        elif choice == "6":
            print("\n夜幕降临，你和希娜结束了今天的工作，回到了各自的房间。")
            time.sleep(1)
            # 更新植物生长
            update_plant_growth()
            # 恢复每日体力
            stamina_daily = 5
            day += 1
            check_love_event(player_name)
            time.sleep(1)

            # 自动保存长期模式进度（每日睡觉后）
            try:
                save_game({
                    "mode": "daily_life",
                    "player_name": player_name,
                    "day": day,
                    "stamina_daily": stamina_daily,
                    "inventory": inventory,
                    "affection": affection,
                    "planting_progress": planting_progress,
                    "planting": planting,
                    "love_triggered": list(love_triggered)
                })
            except Exception as e:
                print(f"长期模式自动存档失败：{e}")

# 启动游戏
start_screen()
player_name = get_player_name()  # 获取玩家名字

choice = input("\n是否跳过开场剧情？(Y/N)：").strip().lower()

# 检查是否存在任意存档，若存在询问是否继续对应模式（可继续扩展）
existing_save = load_game()
if existing_save:
    # 如果是主线存档并且用户选择继续，可以直接从 main_game 的自动读取中恢复
    # 这里不做强制覆盖，只提示用户
    print("检测到上次存档，你可以选择继续上次进度。")
    time.sleep(1)


if choice == "n":
    print("请按回车来推动文本\n")
    paperwork_star(player_name)  # 不跳过，正常播放剧情
    stop_bgm()
    time.sleep(1)
else:
    print("\n【系统】已跳过开场剧情。")
    time.sleep(1)

# 进入主线
main_game(player_name)       # 30天主循环
if pass_game:
    print("请按回车来推动文本\n")
    time.sleep(1)
    paperwork_mid(player_name)
    time.sleep(1)
    stop_bgm()
    daily_life(player_name)

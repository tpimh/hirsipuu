using GLib;
using SDL;
using SDLTTF;

public class Hirsipuu {
    protected static Window window;
    //protected static Renderer renderer;
    protected static Surface screen_surface;
    protected static List<Surface> hangman;
    protected static Font anonpro;

    private static List<unichar> wrong_guess;
    private static List<unichar> right_guess;
    private static List<string> words;
    private static int word_num;

    private const int SCREEN_WIDTH = 800;
    private const int SCREEN_HEIGHT = 600;

    public static void main() {
        if (!init()) {
            Process.exit(1);
        }

        if (!load_media() || !load_words()) {
            Process.exit(1);
        }
        
        select_word();
        
        for (Event e = {0}; e.type != EventType.QUIT; Event.poll (out e)) {
            render();
        
            bool quit = false;
            if (e.type==EventType.KEYDOWN) {
                switch (e.key.keysym.sym) {
                    case Keycode.ESCAPE:
                        quit = true;
                        break;
                    case Keycode.a: case Keycode.b: case Keycode.c: case Keycode.d: case Keycode.e: case Keycode.f: case Keycode.g:
                    case Keycode.h: case Keycode.i: case Keycode.j: case Keycode.k: case Keycode.l: case Keycode.m: case Keycode.n:
                    case Keycode.o: case Keycode.p: case Keycode.q: case Keycode.r: case Keycode.s: case Keycode.t: case Keycode.u:
                    case Keycode.v: case Keycode.w: case Keycode.x: case Keycode.y: case Keycode.z:
                        guess(Keyboard.get_keyname(e.key.keysym.sym)[0]);
                        break;
                    case Keycode.SEMICOLON: 
                    case Keycode.COLON:
                        guess('Ä');
                        break;
                    case Keycode.QUOTE:
                    case Keycode.QUOTEDBL:
                        guess('Ö');
                        break;
                    case Keycode.RETURN:
                        stdout.printf(words.nth_data(word_num) + "\n");
                        break;
                    case Keycode.SPACE:
                        if (wrong_guess.length() >= 6 || right_guess.length() >= get_uniq_chars()) {
                            select_word();
                        }
                        break;
                }
            }
            
            if (quit) {
                break;
            }
        }
        
        SDL.quit();
    }

    private static bool init() {
        // initialize SDL
        if (SDL.init(InitFlag.EVERYTHING) < 0) {
            stderr.printf("SDL could not be initialized! Error: %s\n", get_error());
            return false;
        }

        // initialize SDLTTF
        if (SDLTTF.init() < 0) {
            stderr.printf("SDL could not be initialized! Error: %s\n", get_error());
            return false;
        }

        // create window
        window = new Window("Hirsipuu", Window.POS_UNDEFINED, Window.POS_UNDEFINED,
            SCREEN_WIDTH, SCREEN_HEIGHT, 0);
        if (window == null) {
            stderr.printf("Window could not be created! Error: %s\n", get_error());
            return false;
        }

        // create renderer
        //renderer = new Renderer(window, -1, RendererFlags.ACCELERATED | RendererFlags.PRESENTVSYNC);
        //if (renderer == null) {
        //    stderr.printf("Renderer could not be created! Error: %s\n", get_error());
        //    return false;
        //}

        // get window surface
        screen_surface = window.get_surface();
        if (screen_surface == null) {
            stderr.printf("Screen surface could not be retrieved! Error: %s\n", get_error());
            return false;
        }

        return true;
    }

    private static bool load_media() {
        hangman = new List<Surface>();

        for (int i = 0; i < 7; i++) {
            // load image
            hangman.append(new Surface.from_bmp(@"res/hang$i.bmp"));
            if (hangman.nth_data(i) == null) {
                stderr.printf("Unable to load image %s! Error: %s\n", @"res/hang$i.bmp", get_error());
                return false;
            }
        }
        
        anonpro = new Font("res/AnonymousPro-Regular.ttf", 50);
        if (anonpro == null) {
            stderr.printf("Unable to load font %s! Error: %s\n", "res/AnonymousPro-Regular.ttf", get_error());
            return false;
        }
        
        return true;
    }

    private static void render() {
        //renderer.clear();
        //renderer.set_draw_color(255, 255, 255, 0);
        //renderer.fill_rect( {0, 0, 800, 600} );

        Surface rendertext = anonpro.render_blended_wrapped_utf8(word_to_show(), { 10, 10, 10, 255 }, 240);
        //Texture texturetext = new Texture.from_surface(renderer, rendertext);
        //Texture image = new Texture.from_surface(renderer, hangman.nth_data(wrong_guess.length()));
        
        screen_surface.fill_rect(null, 0xFFFFFF);

        //renderer.copy(image,
        hangman.nth_data(wrong_guess.length()).blit(
            { 0, 0, hangman.nth_data(0).w, hangman.nth_data(0).h },
            screen_surface,
            { 0, 0, hangman.nth_data(0).w, hangman.nth_data(0).h });
        //renderer.copy(texturetext,
        rendertext.blit(
            { 0, 0, rendertext.w, rendertext.h },
            screen_surface,
            { 400 - rendertext.w / 2 , 590 - rendertext.h, rendertext.w, rendertext.h });

        //renderer.present();
        window.update_surface();

        SDL.Timer.delay(25);
    }

    private static bool load_words() {
        words = new List<string>();

        try {
            string read;
            FileUtils.get_contents("res/dict.txt", out read);
            
            read = read.replace(" ", "");
            read = read.up();

            foreach (string str in read.split("\n")) {
                if (str[0] != '#' && str.length != 0) {
                    words.append(str);
                }
            }
        } catch (FileError e) {
            stderr.printf("%s\n", e.message);
            return false;
        }

        return true;
    }

    private static void select_word() {
        right_guess = new List<unichar>();
        wrong_guess = new List<unichar>();
        word_num = Random.int_range(0, (int32) words.length());
    }

    private static void guess(unichar ch) {
        if (wrong_guess.find(ch) == null && right_guess.find(ch) == null &&
            wrong_guess.length() < 6 && right_guess.length() < get_uniq_chars()) {
            bool contains = false;
            for (int i = 0; i < words.nth_data(word_num).length; i++) {
                if (words.nth_data(word_num).valid_char(i)) {
                    if (words.nth_data(word_num).get_char(i) == ch) {
                        contains = true;
                    }
                }
            }

            if (contains) {
                right_guess.append(ch);
            } else {
                wrong_guess.append(ch);
            }
        }
    }

    private static uint get_uniq_chars() {
        List<unichar> existing = new List<unichar>();

        for (int i = 0; i < words.nth_data(word_num).length; i++) {
            if (words.nth_data(word_num).valid_char(i)) {
                bool contains = false;
                foreach (unichar ch in existing) {
                    if (words.nth_data(word_num).get_char(i) == ch) {
                        contains = true;
                    }
                }
                if (!contains) {
                    existing.append(words.nth_data(word_num).get_char(i));
                }
            }
        }

        return existing.length();
    }
    
    private static string word_to_show() {
        string word = "";

        for (int i = 0; i < words.nth_data(word_num).length; i++) {
            if (words.nth_data(word_num).valid_char(i)) {
                bool contains = false;
                foreach (unichar ch in right_guess) {
                    if (words.nth_data(word_num).get_char(i) == ch) {
                        contains = true;
                    }
                }
                if (contains) {
                    word += words.nth_data(word_num).get_char(i).to_string();
                } else {
                    word += "_";
                }
            }
        }

        return word;
    }
}

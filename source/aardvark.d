module aardvark;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;
import derelict.sdl2.net;

import std.stdio;
import std.string;
import std.conv : to;

enum eGLShaderType {
    eGLVertexShader=GL_VERTEX_SHADER,
    eGLFragmentShader=GL_FRAGMENT_SHADER
};

bool createGLShader(uint* shader, string source, eGLShaderType type, char[] infoLog) {
    uint id;
    if(type == eGLShaderType.eGLVertexShader) {
        id = glCreateShader(GL_VERTEX_SHADER);
    } else {
        id = glCreateShader(GL_FRAGMENT_SHADER);
    }
    if(id < 0) {
        return false;
    }

    const char *src_ptr = toStringz(source);
    glShaderSource(id, 1, &src_ptr, null);
    glCompileShader(id);

    int success;
    glGetShaderiv(id, GL_COMPILE_STATUS, &success);
    if(!success) {
        glGetShaderInfoLog(id, cast(uint)(infoLog.length), cast(int *)null, infoLog.ptr);
        glDeleteShader(id);
        return false;
    }
    *shader = id;
    return true;
}

void main() {
    DerelictGL3.load();
    DerelictSDL2.load(SharedLibVersion(2, 0, 9));
    DerelictSDL2Image.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2ttf.load();
    DerelictSDL2Net.load();

    if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO)) {
        writeln("ERROR: Failed to init SDL2");
        return;
    }

    SDL_Window *window;
    SDL_GLContext context;

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    window = SDL_CreateWindow("Aardvark", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                              800, 600, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
    if(!window) {
        writeln("ERROR: Failed to create a window.");
        return;
    }

    SDL_ShowWindow(window);

    SDL_ClearError();
    context = SDL_GL_CreateContext(window);

    if(!context) {
        writeln("ERROR: Failed to obtain OpenGL context: ", to!string(SDL_GetError()));
        return;
    }

    DerelictGL3.reload();

    SDL_GL_SetSwapInterval(1);

    glViewport(0, 0, 800, 600);
    glClearColor(0.0, 0.3, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    /////////////////////////////////////////////////////////////////////////

    uint vertexShader;
    uint fragmentShader;
    char[512] errLogBuf;

    string vertexSource = import("gl_vertex_01.glsl");
    if(!createGLShader(&vertexShader, vertexSource, eGLShaderType.eGLVertexShader, errLogBuf)) {
        // Error out?
        return;
    }

    string fragmentSource = import("gl_fragment_01.glsl");
    if(!createGLShader(&fragmentShader, fragmentSource, eGLShaderType.eGLFragmentShader, errLogBuf)) {
        // Error out?
        return;
    }

    uint shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);

    int success;
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if(!success) {
        glGetProgramInfoLog(shaderProgram, errLogBuf.length, null, errLogBuf.ptr);
        // Error out?
        return;
    }

    //glUseProgram(shaderProgram);
    //glUseProgram(0);
    //glDeleteShader(vertexShader);
    //glDeleteShader(fragmentShader);

    /////////////////////////////////////////////////////////////////////////

    float[] vertices = [
        -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f,
        0.0f, 0.5f, 0.0f
    ];

    uint VBO;
    uint VAO;

    glGenBuffers(1, &VBO);
    glGenVertexArrays(1, &VAO);
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    //assert(vertices.sizeof == (4*9));
    glBufferData(GL_ARRAY_BUFFER, /* vertices.sizeof */ 9 * 4, vertices.ptr, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, null);
    glEnableVertexAttribArray(0);

    /////////////////////////////////////////////////////////////////////////

    SDL_Event event;
    bool done = false;
    while(!done) {
        while(SDL_PollEvent(&event)) {
            if(event.type == SDL_QUIT) {
                done = true;
                break;
            } else if(event.type == SDL_KEYDOWN) {
                switch(event.key.keysym.sym) {
                    default:
                        break;
                    case SDLK_ESCAPE:
                        done = true;
                    break;
                }
            }
        }

        glClearColor(0.0, 0.3, 0.2, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(shaderProgram);
        glBindVertexArray(VAO);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        SDL_GL_SwapWindow(window);
    }

    //SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(window);
    SDL_Quit();
}
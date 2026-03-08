/**
 * 像素动物主题生成器 v2
 * 包含多种像素动物：猫、狗、兔子、熊等
 */

const PixelAnimalTheme = {
  // 像素动物设计库（16x16 网格）
  animals: {
    // 像素猫
    cat: [
      '................',
      '...XX......XX...',
      '..XXXX....XXXX..',
      '.XXXXXX..XXXXXX.',
      '.XXXXXX..XXXXXX.',
      '..XXXXXXXXXXXX..',
      '...XXXXXXXXXX...',
      '....XXXXXXXX....',
      '.....XXXXXX.....',
      '......XXXX......',
      '......XXXX......',
      '.....X..XX..X...',
      '....XX..XX..XX..',
      '...XXX..XX..XXX.',
      '................',
      '................'
    ],
    
    // 像素狗
    dog: [
      '................',
      '....XX....XX....',
      '...XXXX..XXXX...',
      '..XXXXXXXXXXXX..',
      '.XXXXXXXXXXXXXX.',
      '.XXXXXXXXXXXXXX.',
      '..XXXXXXXXXXXX..',
      '...XXXXXXXXXX...',
      '....XXXXXXXX....',
      '.....XXXXXX.....',
      '......XXXX......',
      '.....X....X.....',
      '....XX....XX....',
      '...XXX....XXX...',
      '................',
      '................'
    ],
    
    // 像素兔子
    rabbit: [
      '....XX....XX....',
      '...XXXX..XXXX...',
      '....XX....XX....',
      '....XX....XX....',
      '...XXXXXXXXXX...',
      '..XXXXXXXXXXXX..',
      '.XXXXXXXXXXXXXX.',
      '..XXXXXXXXXXXX..',
      '...XXXXXXXXXX...',
      '....XXXXXXXX....',
      '.....XXXXXX.....',
      '......XXXX......',
      '.....X....X.....',
      '....XX....XX....',
      '................',
      '................'
    ],
    
    // 像素熊
    bear: [
      '................',
      '...XX....XX.....',
      '..XXXX..XXXX....',
      '.XXXXXXXXXXXX...',
      '.XXXXXXXXXXXX...',
      '..XXXXXXXXXX....',
      '...XXXXXXXX.....',
      '....XXXXXXX.....',
      '.....XXXXX......',
      '......XXX.......',
      '.....XXXXX......',
      '....XX...XX.....',
      '...XXX...XXX....',
      '..XXXX...XXXX...',
      '................',
      '................'
    ],
    
    // 像素狐狸
    fox: [
      '...XX....XX.....',
      '..XXXX..XXXX....',
      '.XXXXXXXXXXXX...',
      '..XXXXXXXXXX....',
      '...XXXXXXXX.....',
      '....XXXXXXX.....',
      '.....XXXXX......',
      '......XXX.......',
      '.....XXXXX......',
      '....XX...XX.....',
      '...XXX...XXX....',
      '..XXXX...XXXX...',
      '.XXXXX...XXXXX..',
      '................',
      '................',
      '................'
    ]
  },
  
  // 颜色方案（像素风格）
  colorSchemes: {
    cat: {
      primary: '#ff6b9d',
      secondary: '#c77dff',
      accent: '#00f0ff'
    },
    dog: {
      primary: '#8D6E63',
      secondary: '#A1887F',
      accent: '#FFD54F'
    },
    rabbit: {
      primary: '#FFFFFF',
      secondary: '#E0E0E0',
      accent: '#FFAB91'
    },
    bear: {
      primary: '#5D4037',
      secondary: '#795548',
      accent: '#FFCC80'
    },
    fox: {
      primary: '#FF7043',
      secondary: '#FF8A65',
      accent: '#FFFFFF'
    }
  },
  
  // 当前选择的动物
  currentAnimal: 'cat',
  
  /**
   * 生成像素动物 Canvas
   */
  generateCanvas(animalType = 'cat', size = 64) {
    const design = this.animals[animalType] || this.animals.cat;
    const colors = this.colorSchemes[animalType] || this.colorSchemes.cat;
    
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');
    
    const pixelSize = size / 16;
    
    // 清空画布
    ctx.fillStyle = 'transparent';
    ctx.fillRect(0, 0, size, size);
    
    // 绘制像素动物
    design.forEach((row, y) => {
      for (let x = 0; x < row.length; x++) {
        if (row[x] === 'X') {
          // 渐变效果
          const gradient = ctx.createLinearGradient(
            x * pixelSize, y * pixelSize,
            (x + 1) * pixelSize, (y + 1) * pixelSize
          );
          gradient.addColorStop(0, colors.primary);
          gradient.addColorStop(1, colors.secondary);
          
          ctx.fillStyle = gradient;
          ctx.fillRect(
            x * pixelSize + 0.5,
            y * pixelSize + 0.5,
            pixelSize - 1,
            pixelSize - 1
          );
        }
      }
    });
    
    return canvas;
  },
  
  /**
   * 生成像素动物 SVG
   */
  generateSVG(animalType = 'cat', size = 64) {
    const design = this.animals[animalType] || this.animals.cat;
    const colors = this.colorSchemes[animalType] || this.colorSchemes.cat;
    const pixelSize = size / 16;
    
    let rects = '';
    design.forEach((row, y) => {
      for (let x = 0; x < row.length; x++) {
        if (row[x] === 'X') {
          rects += `<rect x="${x * pixelSize}" y="${y * pixelSize}" width="${pixelSize - 1}" height="${pixelSize - 1}" fill="url(#${animalType}Gradient)"/>`;
        }
      }
    });
    
    return `
      <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="${animalType}Gradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:${colors.primary}"/>
            <stop offset="100%" style="stop-color:${colors.secondary}"/>
          </linearGradient>
        </defs>
        ${rects}
      </svg>
    `;
  },
  
  /**
   * 应用主题到页面
   */
  applyToPage() {
    // 设置 favicon（使用猫作为默认）
    const svgData = this.generateSVG('cat', 64);
    const svgBlob = new Blob([svgData], { type: 'image/svg+xml' });
    const url = URL.createObjectURL(svgBlob);
    
    const link = document.querySelector('link[rel="icon"]');
    if (link) {
      link.href = url;
    }
    
    // 添加像素动物装饰到页面
    this.addPageDecorations();
    
    console.log('[PixelAnimalTheme] 主题已应用，当前动物:', this.currentAnimal);
  },
  
  /**
   * 添加页面装饰
   */
  addPageDecorations() {
    // 清除旧的装饰
    const oldDecorations = document.querySelectorAll('.pixel-animal-decoration');
    oldDecorations.forEach(el => el.remove());
    
    // 创建像素动物装饰元素（四个角落）
    const decorations = [
      { position: 'top-left', animal: 'cat', offset: '10px' },
      { position: 'top-right', animal: 'dog', offset: '10px' },
      { position: 'bottom-left', animal: 'rabbit', offset: '10px' },
      { position: 'bottom-right', animal: 'bear', offset: '10px' }
    ];
    
    decorations.forEach(config => {
      const animal = this.generateCanvas(config.animal, 48);
      animal.className = 'pixel-animal-decoration';
      animal.style.position = 'fixed';
      animal.style.zIndex = '9999';
      animal.style.opacity = '0.7';
      animal.style.pointerEvents = 'none';
      animal.style.transition = 'transform 0.3s ease';
      
      if (config.position.includes('left')) {
        animal.style.left = config.offset;
      }
      if (config.position.includes('right')) {
        animal.style.right = config.offset;
      }
      if (config.position.includes('top')) {
        animal.style.top = config.offset;
      }
      if (config.position.includes('bottom')) {
        animal.style.bottom = config.offset;
      }
      
      // 添加悬停效果
      animal.addEventListener('mouseenter', () => {
        animal.style.transform = 'scale(1.2)';
      });
      animal.addEventListener('mouseleave', () => {
        animal.style.transform = 'scale(1)';
      });
      
      document.body.appendChild(animal);
    });
  },
  
  /**
   * 切换当前动物
   */
  setAnimal(animalType) {
    if (this.animals[animalType]) {
      this.currentAnimal = animalType;
      console.log('[PixelAnimalTheme] 切换到:', animalType);
      return true;
    }
    return false;
  },
  
  /**
   * 获取所有可用动物
   */
  getAvailableAnimals() {
    return Object.keys(this.animals).map(key => ({
      value: key,
      label: this.getAnimalLabel(key)
    }));
  },
  
  /**
   * 获取动物中文名
   */
  getAnimalLabel(key) {
    const labels = {
      cat: '🐱 猫',
      dog: '🐶 狗',
      rabbit: '🐰 兔子',
      bear: '🐻 熊',
      fox: '🦊 狐狸'
    };
    return labels[key] || key;
  }
};

// 导出模块
window.PixelAnimalTheme = PixelAnimalTheme;

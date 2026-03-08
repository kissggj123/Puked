/**
 * Three.js 引擎模块
 * 负责 3D 场景渲染、模型创建和动画
 */

const ThreeEngine = {
  scene: null,
  camera: null,
  renderer: null,
  cupGroup: null,
  liquid: null,
  particles: [],
  spillParticles: [],
  animationId: null,
  currentLiquidType: 'cola',
  quality: 'high',
  fps: 60,
  lastFrameTime: 0,
  
  // 液体属性
  liquidProperties: {
    cola: { viscosity: 0.001, density: 1000, surfaceTension: 0.072, color: 0x8B4513, container: 'cup' },
    water: { viscosity: 0.001, density: 1000, surfaceTension: 0.072, color: 0x4FC3F7, container: 'cup' },
    coffee: { viscosity: 0.002, density: 1010, surfaceTension: 0.070, color: 0x6F4E37, container: 'cup' },
    milk: { viscosity: 0.002, density: 1030, surfaceTension: 0.068, color: 0xFFFFE0, container: 'cup' },
    juice: { viscosity: 0.001, density: 1050, surfaceTension: 0.070, color: 0xFFA500, container: 'cup' },
    rice: { viscosity: 0.1, density: 800, surfaceTension: 0, color: 0xFFFFFF, isParticle: true, container: 'bowl' },
    noodles: { viscosity: 0.05, density: 700, surfaceTension: 0, color: 0xFFF8DC, isParticle: true, container: 'bowl' },
    soup: { viscosity: 0.005, density: 1020, surfaceTension: 0.065, color: 0xFFD54F, container: 'bowl' },
    porridge: { viscosity: 0.08, density: 900, surfaceTension: 0.060, color: 0xF5DEB3, container: 'bowl' }
  },
  
  // 容器类型
  currentContainer: 'cup',
  containerMesh: null,

  /**
   * 初始化 Three.js 场景
   */
  init() {
    const container = document.getElementById('three-container');
    if (!container) {
      console.error('[ThreeEngine] 容器未找到');
      return;
    }

    // 场景
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0f0f1a);
    this.scene.fog = new THREE.Fog(0x0f0f1a, 10, 50);

    // 相机
    const aspect = container.clientWidth / container.clientHeight;
    this.camera = new THREE.PerspectiveCamera(75, aspect, 0.1, 1000);
    this.camera.position.set(0, 2, 5);
    this.camera.lookAt(0, 0, 0);

    // 渲染器
    this.renderer = new THREE.WebGLRenderer({ 
      antialias: this.quality !== 'low',
      alpha: true 
    });
    this.renderer.setSize(container.clientWidth, container.clientHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = this.quality === 'high';
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    container.appendChild(this.renderer.domElement);

    // 灯光
    this.setupLights();

    // 创建场景物体
    this.createSceneObjects();

    // 窗口大小调整
    window.addEventListener('resize', () => this.onWindowResize(), false);

    console.log('[ThreeEngine] 初始化完成');
  },

  /**
   * 设置灯光
   */
  setupLights() {
    // 环境光
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.4);
    this.scene.add(ambientLight);

    // 主光源
    const mainLight = new THREE.DirectionalLight(0xffffff, 0.8);
    mainLight.position.set(5, 5, 5);
    mainLight.castShadow = this.quality === 'high';
    mainLight.shadow.mapSize.width = this.quality === 'high' ? 2048 : 1024;
    mainLight.shadow.mapSize.height = this.quality === 'high' ? 2048 : 1024;
    this.scene.add(mainLight);

    // 补光
    const fillLight = new THREE.DirectionalLight(0xff6b9d, 0.3);
    fillLight.position.set(-5, 2, 3);
    this.scene.add(fillLight);

    // 背光
    const backLight = new THREE.DirectionalLight(0x00f0ff, 0.3);
    backLight.position.set(0, -3, -5);
    this.scene.add(backLight);
  },

  /**
   * 创建场景物体
   */
  createSceneObjects() {
    // 创建容器
    this.createContainer();

    // 创建液体
    this.createLiquid();

    // 添加杯组到场景
    this.scene.add(this.cupGroup);

    // 地面
    const floorGeometry = new THREE.PlaneGeometry(20, 20);
    const floorMaterial = new THREE.MeshStandardMaterial({
      color: 0x1a1a2e,
      roughness: 0.8,
      metalness: 0.2
    });
    const floor = new THREE.Mesh(floorGeometry, floorMaterial);
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -2;
    floor.receiveShadow = this.quality === 'high';
    this.scene.add(floor);

    // 背景粒子
    if (this.quality !== 'low') {
      this.createBackgroundParticles();
    }
  },

  /**
   * 创建容器（杯子/碗）
   */
  createContainer() {
    if (this.containerMesh) {
      this.cupGroup.remove(this.containerMesh);
    }

    if (this.currentContainer === 'bowl') {
      // 碗模型
      const bowlGeometry = new THREE.SphereGeometry(1.5, 32, 16, 0, Math.PI * 2, 0, Math.PI / 2);
      const bowlMaterial = new THREE.MeshPhongMaterial({
        color: 0x1976D2,
        transparent: true,
        opacity: 0.6,
        side: THREE.DoubleSide,
        depthWrite: false
      });
      this.containerMesh = new THREE.Mesh(bowlGeometry, bowlMaterial);
      this.containerMesh.position.y = -0.5;
      this.containerMesh.scale.y = 0.6;
    } else {
      // 杯子模型（默认）
      const cupGeometry = new THREE.CylinderGeometry(1.2, 1, 3, 32, 1, true);
      const cupMaterial = new THREE.MeshPhongMaterial({
        color: 0x1976D2,
        transparent: true,
        opacity: 0.6,
        side: THREE.DoubleSide,
        depthWrite: false
      });
      this.containerMesh = new THREE.Mesh(cupGeometry, cupMaterial);
    }

    this.containerMesh.castShadow = this.quality === 'high';
    this.containerMesh.receiveShadow = this.quality === 'high';
    this.cupGroup.add(this.containerMesh);
  },

  /**
   * 创建液体
   */
  createLiquid() {
    if (this.liquid) {
      this.cupGroup.remove(this.liquid);
    }

    const props = this.liquidProperties[this.currentLiquidType];
    
    // 根据容器调整液体形状
    let liquidGeometry;
    if (this.currentContainer === 'bowl') {
      // 碗中的液体（半球形）
      liquidGeometry = new THREE.SphereGeometry(1.3, 32, 16, 0, Math.PI * 2, 0, Math.PI / 3);
    } else {
      // 杯中的液体（圆柱形）
      liquidGeometry = new THREE.CylinderGeometry(1.1, 0.9, 2.5, 32);
    }
    
    const liquidMaterial = new THREE.MeshPhongMaterial({
      color: props.color,
      transparent: true,
      opacity: 0.9,
      shininess: 100
    });

    this.liquid = new THREE.Mesh(liquidGeometry, liquidMaterial);
    this.liquid.position.y = this.currentContainer === 'bowl' ? -0.3 : -0.3;
    this.liquid.castShadow = this.quality === 'high';
    this.cupGroup.add(this.liquid);
    
    // 如果是颗粒食物，创建粒子效果
    if (props.isParticle) {
      this.createParticleFood(props);
    }
  },

  /**
   * 创建颗粒食物（米饭/面条）
   */
  createParticleFood(props) {
    const particleCount = this.quality === 'high' ? 500 : this.quality === 'medium' ? 200 : 100;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    const sizes = [];

    for (let i = 0; i < particleCount; i++) {
      // 在碗中随机分布
      const angle = Math.random() * Math.PI * 2;
      const radius = Math.random() * 1.2;
      const x = Math.cos(angle) * radius;
      const z = Math.sin(angle) * radius;
      const y = -0.3 + Math.random() * 0.3;

      positions[i * 3] = x;
      positions[i * 3 + 1] = y;
      positions[i * 3 + 2] = z;
      sizes.push(Math.random() * 0.05 + 0.03);
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

    const material = new THREE.PointsMaterial({
      color: props.color,
      size: 0.05,
      transparent: true,
      opacity: 0.8
    });

    const particles = new THREE.Points(geometry, material);
    this.cupGroup.add(particles);
    
    // 保存粒子引用以便更新
    this.particleFood = particles;
  },

  /**
   * 创建撒出粒子
   */
  createSpillParticles() {
    const particleCount = this.quality === 'high' ? 200 : this.quality === 'medium' ? 100 : 50;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    const velocities = [];
    const sizes = [];

    for (let i = 0; i < particleCount; i++) {
      positions[i * 3] = 0;
      positions[i * 3 + 1] = 0;
      positions[i * 3 + 2] = 0;
      
      velocities.push({
        x: (Math.random() - 0.5) * 0.1,
        y: Math.random() * 0.2,
        z: (Math.random() - 0.5) * 0.1
      });
      
      sizes.push(Math.random() * 0.1 + 0.05);
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

    const props = this.liquidProperties[this.currentLiquidType];
    const material = new THREE.PointsMaterial({
      color: props.color,
      size: 0.1,
      transparent: true,
      opacity: 0.6,
      sizeAttenuation: true
    });

    const particles = new THREE.Points(geometry, material);
    particles.position.y = 0.5;
    this.scene.add(particles);
    
    this.spillParticles.push({
      mesh: particles,
      velocities: velocities,
      sizes: sizes,
      active: false,
      age: 0
    });
  },

  /**
   * 更新撒出粒子
   */
  updateSpillParticles(spillAmount) {
    if (this.spillParticles.length === 0) {
      this.createSpillParticles();
    }

    const particle = this.spillParticles[0];
    const positions = particle.mesh.geometry.attributes.position.array;

    // 激活粒子
    if (spillAmount > 0.1 && !particle.active) {
      particle.active = true;
      particle.age = 0;
    }

    if (!particle.active) return;

    const props = this.liquidProperties[this.currentLiquidType];
    const gravity = 0.01;
    const damping = 0.98;

    for (let i = 0; i < particle.velocities.length; i++) {
      const vx = particle.velocities[i].x;
      const vy = particle.velocities[i].y;
      const vz = particle.velocities[i].z;

      // 更新位置
      positions[i * 3] += vx;
      positions[i * 3 + 1] += vy;
      positions[i * 3 + 2] += vz;

      // 应用重力
      particle.velocities[i].y -= gravity;

      // 应用阻尼
      particle.velocities[i].x *= damping;
      particle.velocities[i].y *= damping;
      particle.velocities[i].z *= damping;

      // 地面碰撞
      if (positions[i * 3 + 1] < -2) {
        positions[i * 3 + 1] = -2;
        particle.velocities[i].y *= -0.5;
      }
    }

    particle.mesh.geometry.attributes.position.needsUpdate = true;
    particle.age++;

    // 粒子消失
    if (particle.age > 200) {
      particle.active = false;
      // 重置粒子位置
      for (let i = 0; i < particle.velocities.length; i++) {
        positions[i * 3] = 0;
        positions[i * 3 + 1] = 0.5;
        positions[i * 3 + 2] = 0;
        particle.velocities[i].x = (Math.random() - 0.5) * 0.1;
        particle.velocities[i].y = Math.random() * 0.2;
        particle.velocities[i].z = (Math.random() - 0.5) * 0.1;
      }
    }
  },

  /**
   * 创建背景粒子
   */
  createBackgroundParticles() {
    const particleCount = this.quality === 'high' ? 500 : 100;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);

    for (let i = 0; i < particleCount * 3; i++) {
      positions[i] = (Math.random() - 0.5) * 30;
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

    const material = new THREE.PointsMaterial({
      color: 0x00f0ff,
      size: 0.1,
      transparent: true,
      opacity: 0.5
    });

    const particles = new THREE.Points(geometry, material);
    this.scene.add(particles);
    this.particles.push(particles);
  },

  /**
   * 更新液体类型
   */
  updateLiquidType(type) {
    if (!this.liquidProperties[type]) {
      console.error('[ThreeEngine] 未知的液体类型:', type);
      return;
    }

    this.currentLiquidType = type;
    const props = this.liquidProperties[type];
    
    // 根据液体类型切换容器
    const newContainer = props.container || 'cup';
    if (newContainer !== this.currentContainer) {
      this.currentContainer = newContainer;
      this.createContainer();
    }
    
    // 重新创建液体
    this.createLiquid();
    
    console.log('[ThreeEngine] 液体类型更新为:', type, '容器:', this.currentContainer);
  },

  /**
   * 更新液体状态
   */
  updateLiquid(lateralAccel, longitudinalAccel) {
    if (!this.liquid) return;

    const props = this.liquidProperties[this.currentLiquidType];
    const sensitivity = AppState ? AppState.sensitivity : 1.0;

    // 根据加速度旋转液体
    const maxTilt = Math.PI / 6;
    const tiltX = Math.min(longitudinalAccel * 0.1 * sensitivity, maxTilt);
    const tiltZ = Math.min(lateralAccel * 0.1 * sensitivity, maxTilt);

    // 平滑过渡
    this.liquid.rotation.x += (tiltX - this.liquid.rotation.x) * 0.1;
    this.liquid.rotation.z += (tiltZ - this.liquid.rotation.z) * 0.1;

    // 粘度影响晃动幅度
    const viscosityFactor = 1 / (1 + props.viscosity * 100);
    this.liquid.scale.y = 1 + Math.sin(Date.now() * 0.001) * 0.05 * viscosityFactor;

    // 计算撒出量
    const totalAccel = Math.sqrt(lateralAccel ** 2 + longitudinalAccel ** 2);
    const spillThreshold = 5;
    const spillAmount = totalAccel > spillThreshold ? Math.min((totalAccel - spillThreshold) / 10, 1) : 0;

    // 更新撒出粒子
    if (this.quality !== 'low') {
      this.updateSpillParticles(spillAmount);
    }
  },

  /**
   * 设置质量
   */
  setQuality(quality) {
    const oldQuality = this.quality;
    this.quality = quality;
    
    // 如果质量没变，不重新初始化
    if (oldQuality === quality) return;
    
    // 保存当前液体类型
    const currentLiquid = this.currentLiquidType;
    
    // 重新初始化场景
    this.dispose();
    this.init();
    
    // 恢复液体类型
    this.updateLiquidType(currentLiquid);
  },

  /**
   * 启动动画
   */
  startAnimation() {
    let frameCount = 0;
    let lastTime = performance.now();
    
    const animate = () => {
      this.animationId = requestAnimationFrame(animate);
      
      // FPS 计算
      frameCount++;
      const currentTime = performance.now();
      if (currentTime - lastTime >= 1000) {
        this.fps = frameCount;
        frameCount = 0;
        lastTime = currentTime;
        
        // 自动降级
        if (this.fps < 30 && this.quality === 'high') {
          console.log('[ThreeEngine] FPS 过低，自动降级到中画质');
          this.setQuality('medium');
        } else if (this.fps < 20 && this.quality === 'medium') {
          console.log('[ThreeEngine] FPS 过低，自动降级到低画质');
          this.setQuality('low');
        }
      }
      
      this.render();
    };
    animate();
  },

  /**
   * 停止动画
   */
  stopAnimation() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }
  },

  /**
   * 渲染场景
   */
  render() {
    if (!this.scene || !this.camera || !this.renderer) return;

    // 旋转背景粒子
    if (this.particles.length > 0) {
      this.particles[0].rotation.y += 0.0005;
    }

    this.renderer.render(this.scene, this.camera);
  },

  /**
   * 窗口大小调整
   */
  onWindowResize() {
    const container = document.getElementById('three-container');
    if (!container) return;

    this.camera.aspect = container.clientWidth / container.clientHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(container.clientWidth, container.clientHeight);
  },

  /**
   * 清理资源
   */
  dispose() {
    this.stopAnimation();
    
    // 清理撒出粒子
    this.spillParticles.forEach(p => {
      if (p.mesh && p.mesh.parent) {
        p.mesh.parent.remove(p.mesh);
      }
      if (p.mesh && p.mesh.geometry) {
        p.mesh.geometry.dispose();
      }
      if (p.mesh && p.mesh.material) {
        p.mesh.material.dispose();
      }
    });
    this.spillParticles = [];
    
    if (this.renderer) {
      this.renderer.dispose();
      if (this.renderer.domElement && this.renderer.domElement.parentNode) {
        this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
      }
    }
    
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.cupGroup = null;
    this.liquid = null;
    this.particles = [];
  }
};

// 导出模块
window.ThreeEngine = ThreeEngine;

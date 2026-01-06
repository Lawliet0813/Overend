document.addEventListener('DOMContentLoaded', () => {
    // ========================================
    // SMOOTH SCROLLING
    // ========================================
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            e.preventDefault();
            const targetEl = document.querySelector(targetId);
            if (targetEl) {
                targetEl.scrollIntoView({
                    behavior: 'smooth'
                });
                // Close mobile nav if open
                closeMobileNav();
            }
        });
    });

    // ========================================
    // INTERSECTION OBSERVER FOR ANIMATIONS
    // ========================================
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // Observe all animatable elements
    const animatableElements = document.querySelectorAll('.fade-in, .fade-in-left, .fade-in-right, .scale-in');
    animatableElements.forEach(el => observer.observe(el));

    // Auto-add fade-in class to feature cards
    document.querySelectorAll('.feature-card').forEach(el => {
        if (!el.classList.contains('fade-in')) {
            el.classList.add('fade-in');
        }
        observer.observe(el);
    });

    // Observe section headers
    document.querySelectorAll('.section-header').forEach(el => {
        if (!el.classList.contains('fade-in')) {
            el.classList.add('fade-in');
        }
        observer.observe(el);
    });

    // Observe testimonial cards
    document.querySelectorAll('.testimonial-card').forEach(el => {
        if (!el.classList.contains('fade-in')) {
            el.classList.add('fade-in');
        }
        observer.observe(el);
    });

    // Observe stat items
    document.querySelectorAll('.stat-item').forEach((el, index) => {
        if (!el.classList.contains('fade-in')) {
            el.classList.add('fade-in');
            el.style.transitionDelay = `${index * 0.1}s`;
        }
        observer.observe(el);
    });

    // ========================================
    // HAMBURGER MENU
    // ========================================
    const hamburger = document.querySelector('.hamburger-menu');
    const mobileNav = document.querySelector('.mobile-nav');
    const mobileNavLinks = document.querySelectorAll('.mobile-nav-links a');

    function closeMobileNav() {
        if (hamburger && mobileNav) {
            hamburger.classList.remove('active');
            mobileNav.classList.remove('active');
            document.body.style.overflow = '';
        }
    }

    if (hamburger && mobileNav) {
        hamburger.addEventListener('click', () => {
            hamburger.classList.toggle('active');
            mobileNav.classList.toggle('active');
            
            // Prevent body scroll when menu is open
            if (mobileNav.classList.contains('active')) {
                document.body.style.overflow = 'hidden';
            } else {
                document.body.style.overflow = '';
            }
        });

        // Close mobile nav when clicking a link
        mobileNavLinks.forEach(link => {
            link.addEventListener('click', closeMobileNav);
        });

        // Close mobile nav when clicking outside
        mobileNav.addEventListener('click', (e) => {
            if (e.target === mobileNav) {
                closeMobileNav();
            }
        });
    }

    // ========================================
    // NAVBAR SCROLL EFFECT
    // ========================================
    const nav = document.querySelector('.glass-nav');
    let lastScrollY = window.scrollY;

    window.addEventListener('scroll', () => {
        const currentScrollY = window.scrollY;
        
        if (currentScrollY > 100) {
            nav.style.background = 'rgba(10, 10, 10, 0.9)';
        } else {
            nav.style.background = 'rgba(10, 10, 10, 0.7)';
        }
        
        lastScrollY = currentScrollY;
    });

    // ========================================
    // COUNTER ANIMATION FOR STATS
    // ========================================
    function animateCounter(element, target, duration = 2000) {
        const start = 0;
        const increment = target / (duration / 16);
        let current = start;

        const updateCounter = () => {
            current += increment;
            if (current < target) {
                element.textContent = Math.floor(current).toLocaleString();
                requestAnimationFrame(updateCounter);
            } else {
                element.textContent = target.toLocaleString();
            }
        };

        updateCounter();
    }

    // Observe stat numbers for counter animation
    const statNumbers = document.querySelectorAll('.stat-number');
    const statsObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const el = entry.target;
                const targetValue = parseInt(el.dataset.value, 10);
                if (targetValue) {
                    animateCounter(el, targetValue);
                }
                statsObserver.unobserve(el);
            }
        });
    }, { threshold: 0.5 });

    statNumbers.forEach(el => statsObserver.observe(el));
});

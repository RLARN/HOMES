package com.eksystems.homes.common.interceptor.config;

import com.eksystems.homes.common.interceptor.LoginInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LoginInterceptor())
                .addPathPatterns("/**")
                .excludePathPatterns(
                        "/login", "/login/**",
                        "/loginProcess",
                        "/logout",
                        "/error", "/error/**",
                        "/css/**", "/js/**", "/assets/**",
                        "/img/**",
                        "/favicon.ico",
                        "/sw.js",
                        "/manifest.json"
                );
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/img/**")
                .addResourceLocations("classpath:/img/");

        registry.addResourceHandler("/main/**")
                .addResourceLocations("classpath:/img/main/");
    }
}

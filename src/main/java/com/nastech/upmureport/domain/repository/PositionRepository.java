package com.nastech.upmureport.domain.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nastech.upmureport.domain.entity.Position;

public interface PositionRepository extends JpaRepository<Position, Integer> {

}
